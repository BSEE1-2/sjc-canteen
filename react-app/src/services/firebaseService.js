import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  sendPasswordResetEmail,
  signInWithPopup,
  signInWithEmailAndPassword,
  signOut,
  sendEmailVerification,
  updateProfile,
} from 'firebase/auth'
import { httpsCallable } from 'firebase/functions'
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
import { auth, db, firebaseReady, functions } from '../firebase'

function requireFirebase() {
  if (!firebaseReady || !auth || !db) {
    throw new Error('Firebase is not configured. Add the VITE_FIREBASE_* values to react-app/.env.')
  }
}

export function normalizeStudentEmail(input) {
  const value = input.trim()
  return value.includes('@') ? value : `${value}@student.psjc.edu.ph`
}

const privilegedAdminEmail = 'admin@admin.com'
const studentEmailPattern = /^[^\s@]+@phinmaed\.com$/i
const studentIdPattern = /^\d{2}-\d{4}-\d{6}$/

function requireStudentEmail(email) {
  if (!studentEmailPattern.test(email)) {
    throw new Error('Student accounts must use a valid @phinmaed.com email address.')
  }
}

function requireStudentId(studentId) {
  if (!studentIdPattern.test(studentId)) {
    throw new Error('Student ID must use the format ##-####-###### (for example, 06-2526-004154).')
  }
}

export async function loginWithRole(input, password, expectedRole) {
  requireFirebase()
  const email = expectedRole === 'student' ? normalizeStudentEmail(input) : input.trim()
  const credential = await signInWithEmailAndPassword(auth, email, password)

  const isPrivilegedAdmin = expectedRole === 'admin' && email.toLowerCase() === privilegedAdminEmail
  if (expectedRole === 'student' && !credential.user.emailVerified && !isPrivilegedAdmin) {
    await sendEmailVerification(credential.user)
    await signOut(auth)
    throw new Error('Your email is not verified. We sent a new verification link. Check your inbox and spam folder, then try again.')
  }

  const profile = await getUserProfile(credential.user.uid)

  if (!profile || profile.role !== expectedRole) {
    await signOut(auth)
    throw new Error(`This account is not registered as a ${expectedRole} account.`)
  }

  if (expectedRole === 'owner' && profile.status !== 'approved') {
    await signOut(auth)
    throw new Error(profile.status === 'rejected'
      ? 'Your owner application was not approved. Please contact the administrator.'
      : 'Your owner application is awaiting administrator approval.')
  }

  if (profile.emailVerified !== true) {
    await updateUserProfile(credential.user.uid, { emailVerified: true })
    profile.emailVerified = true
  }

  return { user: credential.user, profile }
}

export async function loginWithGoogle(expectedRole) {
  requireFirebase()
  const credential = await signInWithPopup(auth, new GoogleAuthProvider())
  if (expectedRole === 'student') {
    try {
      requireStudentEmail(credential.user.email || '')
    } catch (error) {
      await signOut(auth)
      throw error
    }
  }
  let profile = await getUserProfile(credential.user.uid)

  if (!profile && expectedRole === 'student') {
    profile = {
      uid: credential.user.uid,
      name: credential.user.displayName || credential.user.email?.split('@')[0] || 'Student',
      email: credential.user.email || '',
      role: 'student',
      studentId: credential.user.email?.split('@')[0] || credential.user.uid.slice(0, 8),
      status: 'active',
      createdAt: serverTimestamp(),
    }
    await setDoc(doc(db, 'users', credential.user.uid), profile)
  }

  if (!profile || profile.role !== expectedRole) {
    await signOut(auth)
    throw new Error(`This account is not registered as a ${expectedRole} account.`)
  }

  if (expectedRole === 'owner' && profile.status !== 'approved') {
    await signOut(auth)
    throw new Error(profile.status === 'rejected'
      ? 'Your owner application was not approved. Please contact the administrator.'
      : 'Your owner application is awaiting administrator approval.')
  }

  return { user: credential.user, profile }
}

export async function createStudentAccount({ email, password, name, studentId }) {
  requireFirebase()
  const normalizedEmail = email.trim().toLowerCase()
  const normalizedStudentId = studentId.trim()
  requireStudentEmail(normalizedEmail)
  requireStudentId(normalizedStudentId)
  const credential = await createUserWithEmailAndPassword(auth, normalizedEmail, password)
  await updateProfile(credential.user, { displayName: name.trim() })
  await setDoc(doc(db, 'users', credential.user.uid), {
    uid: credential.user.uid,
    name: name.trim(),
    email: normalizedEmail,
    role: 'student',
    studentId: normalizedStudentId,
    status: 'active',
    emailVerified: false,
    createdAt: serverTimestamp(),
  })
  await sendEmailVerification(credential.user)
  await signOut(auth)
  return { requiresEmailVerification: true }
}

export async function createOwnerAccount({ email, password, name, storeName }) {
  requireFirebase()
  const normalizedEmail = email.trim().toLowerCase()
  const credential = await createUserWithEmailAndPassword(auth, normalizedEmail, password)
  await updateProfile(credential.user, { displayName: name.trim() })
  await setDoc(doc(db, 'users', credential.user.uid), {
    uid: credential.user.uid,
    name: name.trim(),
    email: normalizedEmail,
    role: 'owner',
    status: 'pending',
    storeName: storeName.trim() || `${name.trim()}'s Store`,
    bannerImage: '',
    logoImage: '',
    emailVerified: true,
    createdAt: serverTimestamp(),
  })
  await signOut(auth)
  return { requiresApproval: true }
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

export async function deleteUserAccount(uid) {
  requireFirebase()
  if (!functions) throw new Error('Firebase Functions is not configured.')
  const deleteAccount = httpsCallable(functions, 'deleteUserAccount')
  await deleteAccount({ uid })
}

export async function askAssistant(question) {
  const response = await fetch('/api/ollama/chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: import.meta.env.VITE_OLLAMA_MODEL || 'gemma3:1b',
      stream: false,
      options: { temperature: 0.2, num_predict: 180 },
      messages: [
        {
          role: 'system',
          content: 'You are the SJC Canteen help assistant. Answer only questions about the app workflow: student ordering, owner inventory and orders, admin approval, account management, authentication, and troubleshooting. Use at most 3 short sentences or bullets. Never ask for, infer, or reveal passwords, API keys, Firebase data, user profiles, orders, or other private information. If unrelated, say you can only help with SJC Canteen.',
        },
        { role: 'user', content: question },
      ],
    }),
  })

  if (!response.ok) {
    throw new Error('Local AI is unavailable. Start Ollama and run the selected model first.')
  }

  const result = await response.json()
  const answer = result.message?.content?.trim()
  if (!answer) throw new Error('Local AI returned no answer.')
  return answer
}

export function subscribeToOwnerStores(onData, onError) {
  requireFirebase()
  return onSnapshot(query(collection(db, 'users'), where('role', '==', 'owner'), where('status', '==', 'approved')), (snapshot) => {
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
    studentEmail: profile?.email || auth.currentUser.email || '',
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
