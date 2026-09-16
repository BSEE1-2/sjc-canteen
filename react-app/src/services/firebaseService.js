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
  onSnapshot,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
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

export async function getUserProfile(uid) {
  requireFirebase()
  const snapshot = await getDoc(doc(db, 'users', uid))
  return snapshot.exists() ? snapshot.data() : null
}

export function subscribeToFoodItems(onData, onError) {
  requireFirebase()
  return onSnapshot(collection(db, 'foodItems'), (snapshot) => {
    onData(snapshot.docs.map((item) => ({ id: item.id, ...item.data() })))
  }, onError)
}

export function subscribeToStudentOrders(uid, onData, onError) {
  requireFirebase()
  const ordersQuery = query(collection(db, 'orders'), where('studentUiD', '==', uid))
  return onSnapshot(ordersQuery, (snapshot) => {
    onData(snapshot.docs.map((item) => ({ id: item.id, ...item.data() })))
  }, onError)
}

export async function placeStudentOrder(cartItems, paymentMethod) {
  requireFirebase()
  if (!auth.currentUser) {
    throw new Error('You must be signed in to place an order.')
  }

  const profile = await getUserProfile(auth.currentUser.uid)
  const total = cartItems.reduce((sum, item) => sum + item.price, 0)
  const order = {
    studentUiD: auth.currentUser.uid,
    studentName: profile?.name || auth.currentUser.displayName || 'Student',
    studentId: profile?.studentId || '',
    itemsDescription: cartItems.map((item) => `1x ${item.name}`).join(', '),
    cartItems: cartItems.map((item) => ({
      title: item.name,
      quantity: 1,
      price: item.price,
      category: item.category,
    })),
    total,
    paymentMethod,
    paymentStatus: paymentMethod === 'Cash on Pickup' ? 'Pay on pickup' : 'Pending confirmation',
    timestamp: serverTimestamp(),
    status: 'Pending',
  }

  const orderReference = await addDoc(collection(db, 'orders'), order)
  return orderReference.id
}

export function subscribeToAllOrders(onData, onError) {
  requireFirebase()
  return onSnapshot(collection(db, 'orders'), (snapshot) => {
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

export async function addFoodItem(item) {
  requireFirebase()
  await addDoc(collection(db, 'foodItems'), {
    title: item.title,
    price: Number(item.price),
    category: item.category,
    networkImage: item.networkImage || '',
    isAvailable: true,
    createdAt: serverTimestamp(),
  })
}

export async function updateFoodItem(itemId, item) {
  requireFirebase()
  await updateDoc(doc(db, 'foodItems', itemId), {
    title: item.title,
    price: Number(item.price),
    category: item.category,
    networkImage: item.networkImage || '',
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
      message: `Your order #${orderId.slice(0, 5)} is now ${status}`,
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
