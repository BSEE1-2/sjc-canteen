import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  sendPasswordResetEmail,
  signInWithPopup,
  signInWithEmailAndPassword,
  signOut,
  updateProfile,
} from 'firebase/auth'
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  onSnapshot,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore'
import { auth, db, firebaseReady } from '../firebase'

function requireFirebase() {
  if (!firebaseReady || !auth || !db) {
    throw new Error('Firebase is not configured. Add the VITE_FIREBASE_* values to react-app/.env.')
  }
}

export function normalizeStudentEmail(input) {
  const value = input.trim()
  return value.includes('@') ? value : `${value}@student.psjc.edu.ph`
}

export async function loginWithRole(input, password, expectedRole) {
  requireFirebase()
  const email = expectedRole === 'student' ? normalizeStudentEmail(input) : input.trim()
  const credential = await signInWithEmailAndPassword(auth, email, password)
  const profile = await getUserProfile(credential.user.uid)

  if (!profile || profile.role !== expectedRole) {
    await signOut(auth)
    throw new Error(`This account is not registered as a ${expectedRole} account.`)
  }

  return { user: credential.user, profile }
}

export async function loginWithGoogle(expectedRole) {
  requireFirebase()
  const credential = await signInWithPopup(auth, new GoogleAuthProvider())
  let profile = await getUserProfile(credential.user.uid)

  if (!profile && expectedRole === 'student') {
    profile = {
      uid: credential.user.uid,
      name: credential.user.displayName || credential.user.email?.split('@')[0] || 'Student',
      email: credential.user.email || '',
      role: 'student',
      studentId: credential.user.email?.split('@')[0] || credential.user.uid.slice(0, 8),
      createdAt: serverTimestamp(),
    }
    await setDoc(doc(db, 'users', credential.user.uid), profile)
  }

  if (!profile || profile.role !== expectedRole) {
    await signOut(auth)
    throw new Error(`This account is not registered as a ${expectedRole} account.`)
  }

  return { user: credential.user, profile }
}

export async function createStudentAccount({ email, password, name, studentId }) {
  requireFirebase()
  const credential = await createUserWithEmailAndPassword(auth, email.trim(), password)
  await updateProfile(credential.user, { displayName: name.trim() })
  await setDoc(doc(db, 'users', credential.user.uid), {
    uid: credential.user.uid,
    name: name.trim(),
    email: email.trim(),
    role: 'student',
    studentId: studentId.trim(),
    createdAt: serverTimestamp(),
  })
  return credential.user
}

export async function createOwnerAccount({ email, password, name, storeName }) {
  requireFirebase()
  const credential = await createUserWithEmailAndPassword(auth, email.trim(), password)
  await updateProfile(credential.user, { displayName: name.trim() })
  await setDoc(doc(db, 'users', credential.user.uid), {
    uid: credential.user.uid,
    name: name.trim(),
    email: email.trim(),
    role: 'owner',
    storeName: storeName.trim() || `${name.trim()}'s Store`,
    bannerImage: '',
    logoImage: '',
    createdAt: serverTimestamp(),
  })
  return credential.user
}

export async function getUserProfile(uid) {
  requireFirebase()
  const snapshot = await getDoc(doc(db, 'users', uid))
  return snapshot.exists() ? snapshot.data() : null
}

export function subscribeToAllUsers(onData, onError) {
  requireFirebase()
  return onSnapshot(collection(db, 'users'), (snapshot) => {
    onData(snapshot.docs.map((item) => ({ id: item.id, ...item.data() })))
  }, onError)
}

export async function deleteUserProfile(uid) {
  requireFirebase()
  await deleteDoc(doc(db, 'users', uid))
}

export function subscribeToOwnerStores(onData, onError) {
  requireFirebase()
  return onSnapshot(query(collection(db, 'users'), where('role', '==', 'owner')), (snapshot) => {
    const stores = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
    stores.sort((first, second) => {
      const firstTime = first.createdAt?.toMillis?.() || 0
      const secondTime = second.createdAt?.toMillis?.() || 0
      return secondTime - firstTime
    })
    onData(stores)
  }, onError)
}

export function subscribeToFoodItems(storeIdOrOnData, onDataMaybe, onErrorMaybe) {
  requireFirebase()

  if (typeof storeIdOrOnData === 'function') {
    return onSnapshot(collection(db, 'foodItems'), (snapshot) => {
      const items = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
      items.sort((first, second) => {
        const firstTime = first.createdAt?.toMillis?.() || 0
        const secondTime = second.createdAt?.toMillis?.() || 0
        return secondTime - firstTime
      })
      storeIdOrOnData(items)
    }, onErrorMaybe || (() => {}))
  }

  return onSnapshot(query(collection(db, 'foodItems'), where('storeId', '==', storeIdOrOnData)), (snapshot) => {
    const items = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
    items.sort((first, second) => {
      const firstTime = first.createdAt?.toMillis?.() || 0
      const secondTime = second.createdAt?.toMillis?.() || 0
      return secondTime - firstTime
    })
    onDataMaybe(items)
  }, onErrorMaybe || (() => {}))
}

export function subscribeToStudentOrders(uid, onData, onError) {
  requireFirebase()
  const ordersQuery = query(collection(db, 'orders'), where('studentUiD', '==', uid))
  return onSnapshot(ordersQuery, (snapshot) => {
    onData(snapshot.docs.map((item) => ({ id: item.id, ...item.data() })))
  }, onError)
}

export function subscribeToStoreActiveOrders(storeId, onData, onError) {
  requireFirebase()
  const activeStatuses = ['Pending', 'Accepted', 'Preparing', 'Ready for Pickup']
  const ordersQuery = query(
    collection(db, 'orders'),
    where('storeId', '==', storeId),
    where('status', 'in', activeStatuses),
  )

  return onSnapshot(ordersQuery, (snapshot) => {
    const orders = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
    orders.sort((first, second) => {
      const firstTime = first.timestamp?.toMillis?.() || 0
      const secondTime = second.timestamp?.toMillis?.() || 0
      return firstTime - secondTime
    })
    onData(orders)
  }, onError)
}

export async function placeStudentOrder(cartItems, paymentMethod, storeId = '') {
  requireFirebase()
  if (!auth.currentUser) {
    throw new Error('You must be signed in to place an order.')
  }

  const profile = await getUserProfile(auth.currentUser.uid)
  const storeProfile = storeId ? await getUserProfile(storeId) : null
  const total = cartItems.reduce((sum, item) => sum + Number(item.price || 0), 0)
  const ticketNumber = String(Date.now()).slice(-6)
  const order = {
    studentUiD: auth.currentUser.uid,
    studentName: profile?.name || auth.currentUser.displayName || 'Student',
    studentId: profile?.studentId || '',
    storeId: storeId || '',
    storeName: storeProfile?.storeName || 'SJC Canteen',
    itemsDescription: cartItems.map((item) => `1x ${item.title || item.name || 'Menu item'}`).join(', '),
    cartItems: cartItems.map((item) => ({
      title: item.title || item.name || 'Menu item',
      quantity: 1,
      price: Number(item.price || 0),
      category: item.category,
    })),
    total,
    paymentMethod,
    paymentStatus: paymentMethod === 'Cash on Pickup' ? 'Pay on pickup' : 'Pending confirmation',
    ticketNumber,
    timestamp: serverTimestamp(),
    status: 'Pending',
  }

  const orderReference = await addDoc(collection(db, 'orders'), order)
  return orderReference.id
}

export function subscribeToAllOrders(storeId, onData, onError) {
  requireFirebase()
  const ordersQuery = storeId
    ? query(collection(db, 'orders'), where('storeId', '==', storeId))
    : query(collection(db, 'orders'))

  return onSnapshot(ordersQuery, (snapshot) => {
    const orders = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
    orders.sort((first, second) => {
      const firstTime = first.timestamp?.toMillis?.() || 0
      const secondTime = second.timestamp?.toMillis?.() || 0
      return secondTime - firstTime
    })
    onData(orders)
  }, onError)
}

export function subscribeToNotifications(uid, onData, onError) {
  requireFirebase()
  return onSnapshot(query(collection(db, 'notifications'), where('userId', '==', uid)), (snapshot) => {
    const notifications = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
    notifications.sort((first, second) => (second.timestamp?.toMillis?.() || 0) - (first.timestamp?.toMillis?.() || 0))
    onData(notifications)
  }, onError)
}

export async function markNotificationRead(notificationId) {
  requireFirebase()
  await updateDoc(doc(db, 'notifications', notificationId), { isRead: true })
}

export async function addFoodItem(item, storeIdOverride) {
  requireFirebase()
  const storeOwnerId = storeIdOverride || auth.currentUser?.uid
  if (!storeOwnerId) {
    throw new Error('No store is available for this inventory update.')
  }

  await addDoc(collection(db, 'foodItems'), {
    title: item.title,
    description: String(item.description || '').trim(),
    price: Number(item.price),
    category: item.category,
    isAvailable: true,
    storeId: storeOwnerId,
    createdAt: serverTimestamp(),
  })
}

export async function updateFoodItem(itemId, item) {
  requireFirebase()
  await updateDoc(doc(db, 'foodItems', itemId), {
    title: item.title,
    description: String(item.description || '').trim(),
    price: Number(item.price),
    category: item.category,
  })
}

export async function toggleFoodAvailability(itemId, isAvailable) {
  requireFirebase()
  await updateDoc(doc(db, 'foodItems', itemId), { isAvailable: !isAvailable })
}

export async function deleteFoodItem(itemId) {
  requireFirebase()
  await deleteDoc(doc(db, 'foodItems', itemId))
}

export async function clearStudentOrders(uid) {
  requireFirebase()
  const snapshot = await getDocs(query(collection(db, 'orders'), where('studentUiD', '==', uid)))
  const batch = writeBatch(db)
  snapshot.docs.forEach((item) => batch.delete(item.ref))
  await batch.commit()
}

export async function clearStoreOrders(storeId) {
  requireFirebase()
  const snapshot = await getDocs(query(collection(db, 'orders'), where('storeId', '==', storeId)))
  const batch = writeBatch(db)
  snapshot.docs.forEach((item) => batch.delete(item.ref))
  await batch.commit()
}

export async function updateUserProfile(uid, profile) {
  requireFirebase()
  await updateDoc(doc(db, 'users', uid), profile)
}

export async function updateOrderStatus(orderId, status) {
  requireFirebase()
  await updateDoc(doc(db, 'orders', orderId), {
    status,
    updatedAt: serverTimestamp(),
  })
  const orderSnapshot = await getDoc(doc(db, 'orders', orderId))
  const order = orderSnapshot.data()
  if (order?.studentUiD) {
    await addDoc(collection(db, 'notifications'), {
      userId: order.studentUiD,
      title: 'Order Update',
      message: `Ticket #${order.ticketNumber || orderId.slice(-6)} is now ${status}`,
      timestamp: serverTimestamp(),
      isRead: false,
      type: 'order_update',
    })
  }
}

export async function requestPasswordReset(email) {
  requireFirebase()
  await sendPasswordResetEmail(auth, email.trim())
}

export async function logout() {
  requireFirebase()
  await signOut(auth)
}
