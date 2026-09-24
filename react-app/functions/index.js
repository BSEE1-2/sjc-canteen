const { initializeApp } = require('firebase-admin/app')
const { getAuth } = require('firebase-admin/auth')
const { getFirestore } = require('firebase-admin/firestore')
const { onCall, HttpsError } = require('firebase-functions/v2/https')

initializeApp()

exports.deleteUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'You must be signed in as an administrator.')
  }

  const callerProfile = await getFirestore().collection('users').doc(request.auth.uid).get()
  if (!callerProfile.exists || callerProfile.data().role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only administrators can delete accounts.')
  }

  const uid = request.data?.uid
  if (typeof uid !== 'string' || !uid || uid === request.auth.uid) {
    throw new HttpsError('invalid-argument', 'A different user ID is required.')
  }

  try {
    await getAuth().deleteUser(uid)
    await getFirestore().collection('users').doc(uid).delete()
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      await getFirestore().collection('users').doc(uid).delete()
      return { deleted: true }
    }
    throw new HttpsError('internal', 'The account could not be deleted.')
  }

  return { deleted: true }
})
