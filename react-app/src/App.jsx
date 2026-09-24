import { BrowserRouter, Routes, Route, useLocation, useNavigate } from 'react-router-dom'
import { useEffect, useMemo, useState } from 'react'
import ReactMarkdown from 'react-markdown'
import { onAuthStateChanged } from 'firebase/auth'
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, Divider, Drawer, IconButton, MenuItem, Slide, TextField, Typography } from '@mui/material'
import { AddShoppingCart, ArrowBack, Close, DeleteSweep, Fastfood, Google, History, LocalCafe, NotificationsNone, Restaurant, Send, SmartToy, Storefront, Visibility, VisibilityOff } from '@mui/icons-material'

const appLogo = '/logoapp.png'
const welcomeImage = '/onboarding_1.png'
const canteenImage = '/canteen.jpg'
import {
  addFoodItem,
  askAssistant,
  clearStoreOrders,
  clearStudentOrders,
  createOwnerAccount,
  createStudentAccount,
  deleteFoodItem,
  deleteUserAccount,
  getUserProfile,
  loginWithGoogle,
  loginWithRole,
  logout as logoutUser,
  markNotificationRead,
  placeStudentOrder,
  requestPasswordReset,
  subscribeToAllOrders,
  subscribeToAllUsers,
  subscribeToFoodItems,
  subscribeToNotifications,
  subscribeToOwnerStores,
  subscribeToStoreActiveOrders,
  subscribeToStudentOrders,
  toggleFoodAvailability,
  updateFoodItem,
  updateOrderStatus,
  updateUserProfile,
} from './services/firebaseService'
import { auth } from './firebase'
import './App.css'

function formatFirebaseError(error, fallback = 'Something went wrong. Please try again.') {
  if (!error) return fallback
  if (error.code === 'permission-denied') return 'Firebase permissions are blocking this action. Deploy the Firestore rules, then try again.'
  return error.message || fallback
}

function FoodCategoryIcon({ category }) {
  if (category === 'Drinks') return <LocalCafe />
  if (category === 'Snacks') return <Fastfood />
  return <Restaurant />
}

function LoadingIndicator({ label = 'Loading' }) {
  return (
    <span className="m3-loading" role="status" aria-label={label}>
      <span />
      <span />
      <span />
      <span />
    </span>
  )
}

function AssistantDrawer() {
  const [open, setOpen] = useState(false)
  const [question, setQuestion] = useState('')
  const [messages, setMessages] = useState([
    { id: 'welcome', role: 'assistant', content: 'Ask me how the app works.' },
  ])
  const [isLoading, setIsLoading] = useState(false)
  const [ollamaReady, setOllamaReady] = useState(null)

  useEffect(() => {
    if (!open) return undefined

    let cancelled = false
    fetch('/api/ollama/tags')
      .then((response) => {
        if (!response.ok) throw new Error('Ollama is unavailable')
        return response.json()
      })
      .then(() => {
        if (!cancelled) setOllamaReady(true)
      })
      .catch(() => {
        if (!cancelled) setOllamaReady(false)
      })

    return () => {
      cancelled = true
    }
  }, [open])

  const submitQuestion = async (event) => {
    event.preventDefault()
    if (!question.trim() || isLoading) return
    const submittedQuestion = question.trim()
    setQuestion('')
    setMessages((current) => [...current, { id: `${Date.now()}-user`, role: 'user', content: submittedQuestion }])
    setIsLoading(true)
    try {
      const response = await askAssistant(submittedQuestion)
      setMessages((current) => [...current, { id: `${Date.now()}-assistant`, role: 'assistant', content: response }])
    } catch (error) {
      setMessages((current) => [...current, { id: `${Date.now()}-error`, role: 'assistant', content: error.message || 'The assistant is unavailable right now.', error: true }])
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <>
      <IconButton
        color="primary"
        onClick={() => setOpen(true)}
        aria-label="Open SJC Canteen assistant"
        sx={{ position: 'fixed', right: 20, bottom: 148, zIndex: 1100, width: 56, height: 56, p: 0, borderRadius: '50%', bgcolor: 'background.paper', boxShadow: 4 }}
      >
        <SmartToy />
      </IconButton>
      <Drawer
        anchor="right"
        open={open}
        onClose={() => setOpen(false)}
        slots={{ transition: Slide }}
        slotProps={{
          transition: { direction: 'left', timeout: { enter: 280, exit: 220 } },
          paper: { sx: { borderRadius: '24px 0 0 24px' } },
        }}
      >
        <Box sx={{ width: { xs: 'min(100vw, 360px)', sm: 380 }, p: 3, display: 'flex', flexDirection: 'column', gap: 2, height: '100%', boxSizing: 'border-box' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <SmartToy color="primary" />
              <Typography variant="h6" fontWeight={800}>Canteen Assistant</Typography>
            </Box>
            <IconButton onClick={() => setOpen(false)} aria-label="Close assistant"><Close /></IconButton>
          </Box>
          <Typography variant="body2" color="text.secondary">Brief answers about ordering, accounts, approvals, and app features.</Typography>
          <Typography variant="caption" color={ollamaReady === false ? 'error.main' : 'success.main'}>
            {ollamaReady === null ? 'Checking local AI connection...' : ollamaReady ? 'Local AI connected' : 'Ollama is offline. Start Ollama to ask questions.'}
          </Typography>
          <Divider />
          <Box sx={{ flex: 1, overflowY: 'auto', p: 1, bgcolor: 'background.default', borderRadius: 2, display: 'flex', flexDirection: 'column', gap: 1.5 }}>
            {messages.map((message) => (
              <Box
                key={message.id}
                sx={{
                  alignSelf: message.role === 'user' ? 'flex-end' : 'flex-start',
                  maxWidth: '86%',
                  px: 1.5,
                  py: 1,
                  borderRadius: message.role === 'user' ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                  bgcolor: message.role === 'user' ? 'primary.main' : 'background.paper',
                  color: message.role === 'user' ? 'primary.contrastText' : message.error ? 'error.main' : 'text.primary',
                  boxShadow: 1,
                  animation: 'assistant-message-send 260ms cubic-bezier(0.2, 0.8, 0.2, 1) both',
                }}
              >
                {message.role === 'assistant' ? (
                  <Box className="assistant-markdown">
                    <ReactMarkdown>{message.content}</ReactMarkdown>
                  </Box>
                ) : (
                  <Typography variant="body2" sx={{ whiteSpace: 'pre-wrap' }}>{message.content}</Typography>
                )}
              </Box>
            ))}
            {isLoading && (
              <Box sx={{ alignSelf: 'flex-start', px: 1.5, py: 1, borderRadius: '16px 16px 16px 4px', bgcolor: 'background.paper', boxShadow: 1 }}>
                <LoadingIndicator label="Assistant is typing" />
              </Box>
            )}
          </Box>
          <Box component="form" onSubmit={submitQuestion} sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
            <TextField
              fullWidth
              multiline
              maxRows={3}
              size="small"
              label="Ask a question"
              value={question}
              onChange={(event) => setQuestion(event.target.value)}
              inputProps={{ maxLength: 500 }}
            />
            <IconButton type="submit" color="primary" disabled={isLoading || !question.trim()} aria-label="Send question">
              {isLoading ? <LoadingIndicator label="Asking assistant" /> : <Send />}
            </IconButton>
          </Box>
        </Box>
      </Drawer>
    </>
  )
}

function OrderProgressTracker({ status }) {
  const stages = ['Pending', 'Accepted', 'Preparing', 'Ready for Pickup']
  const currentIndex = Math.max(0, stages.indexOf(status))

  return (
    <div className="order-progress" aria-label={`Order progress: ${status}`}>
      {stages.map((stage, index) => (
        <div className={index <= currentIndex ? 'progress-stage complete' : 'progress-stage'} key={stage}>
          <span className="progress-dot" />
          <span>{stage === 'Ready for Pickup' ? 'Ready' : stage}</span>
        </div>
      ))}
    </div>
  )
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<OnboardingScreen />} />
        <Route path="/role-selection" element={<RoleSelectionScreen />} />
        <Route path="/login" element={<StudentLoginScreen />} />
        <Route path="/owner-login" element={<OwnerLoginScreen />} />
        <Route path="/owner-register" element={<OwnerRegisterScreen />} />
        <Route path="/admin-login" element={<AdminLoginScreen />} />
        <Route path="/forgot-password" element={<ForgotPasswordScreen />} />
        <Route path="/create-account" element={<CreateAccountScreen />} />
        <Route path="/notifications" element={<NotificationsScreen />} />
        <Route path="/student-home" element={<StudentNavigationScreen />} />
        <Route path="/owner-home" element={<OwnerNavigationScreen />} />
        <Route path="/admin-home" element={<AdminNavigationScreen />} />
      </Routes>
    </BrowserRouter>
  )
}

function OnboardingScreen() {
  const navigate = useNavigate()
  const [page, setPage] = useState(0)

  const slides = [
    { title: 'Order from anywhere', description: 'Skip the line and order your favorite meals right from your classroom.', image: welcomeImage },
    { title: 'Track in real time', description: 'Know exactly when your order is being prepared and ready for pickup.', image: '/students.jpg' },
    { title: 'Empowering canteens', description: 'Owners can manage inventory, orders, and sales from one dashboard.', image: canteenImage },
  ]

  const slide = slides[page]

  return (
    <div className="screen-shell onboarding-shell">
      <div className="brand-row">
        <img className="brand-logo" src={appLogo} alt="SJC Canteen" />
        <span>SJC Canteen</span>
        {page < slides.length - 1 && (
          <Button className="skip-button" variant="text" onClick={() => navigate('/role-selection')}>
            Skip
          </Button>
        )}
      </div>

      <div className="onboarding-card">
        <img className="onboarding-image" src={slide.image} alt="" />
        <h1>{slide.title}</h1>
        <p>{slide.description}</p>
      </div>

      <div className="onboarding-dots" aria-label={`Introduction step ${page + 1} of ${slides.length}`}>
        {slides.map((item, index) => (
          <button
            key={item.title}
            type="button"
            className={index === page ? 'onboarding-dot active' : 'onboarding-dot'}
            onClick={() => setPage(index)}
            aria-label={`Go to step ${index + 1}`}
          />
        ))}
      </div>

      <div className="onboarding-actions">
        <Button variant="contained" fullWidth onClick={() => (page === slides.length - 1 ? navigate('/role-selection') : setPage((current) => current + 1))}>
          {page === slides.length - 1 ? 'Get Started' : 'Continue'}
        </Button>
      </div>
    </div>
  )
}

function RoleSelectionScreen() {
  const navigate = useNavigate()
  const [logoClicks, setLogoClicks] = useState(0)

  const handleLogoClick = () => {
    const nextClickCount = logoClicks + 1
    if (nextClickCount >= 5) {
      setLogoClicks(0)
      navigate('/admin-login')
      return
    }
    setLogoClicks(nextClickCount)
  }

  return (
    <div className="screen-shell role-shell">
      <div className="header-row">
        <button type="button" className="logo-easter-egg" onClick={handleLogoClick} aria-label="SJC Canteen logo">
          <img className="brand-logo small" src={appLogo} alt="SJC Canteen" />
        </button>
        <h2>SJC Canteen</h2>
      </div>

      <div className="role-select-wrap">
        <div className="role-card">
          <div className="role-emoji">🎓</div>
          <h3>Customer</h3>
          <p>Browse daily menus and pre-order your meals in minutes.</p>
          <Button variant="contained" fullWidth onClick={() => navigate('/login')}>
            I am a Customer
          </Button>
        </div>

        <div className="role-card">
          <div className="role-emoji">🏪</div>
          <h3>Store</h3>
          <p>Manage inventory, orders, and customer payments from one place.</p>
          <Button variant="outlined" color="secondary" fullWidth onClick={() => navigate('/owner-login')}>
            I represent a Store
          </Button>
        </div>
      </div>
    </div>
  )
}

function StudentLoginScreen() {
  const navigate = useNavigate()
  const location = useLocation()
  const [studentId, setStudentId] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [infoMessage] = useState(location.state?.message || '')
  const [isLoading, setIsLoading] = useState(false)

  const handleLogin = async (event) => {
    event.preventDefault()
    if (!studentId.trim() || !password.trim()) {
      setError('Please enter both ID/Email and Password')
      return
    }

    setError('')
    setIsLoading(true)
    try {
      await loginWithRole(studentId, password, 'student')
      navigate('/student-home')
    } catch (loginError) {
      setError(loginError.message || 'Invalid credentials or user does not exist.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    setError('')
    setIsLoading(true)
    try {
      await loginWithGoogle('student')
      navigate('/student-home')
    } catch (loginError) {
      setError(loginError.message || 'Google sign-in was not completed.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/role-selection')} aria-label="Go back"><ArrowBack /></IconButton>
        <img className="brand-logo small" src={appLogo} alt="SJC Canteen" />
      </div>

      <div className="login-illustration gradient-amber"><span>Customer Login</span></div>
      <h1>Welcome Back!</h1>
      <p className="subtitle">Log in to your school ordering account</p>

      <form className="login-form" onSubmit={handleLogin}>
        <label>
          <span>Customer ID</span>
          <TextField fullWidth label="Customer ID or Email" value={studentId} onChange={(event) => setStudentId(event.target.value)} />
        </label>

        <label>
          <span>Password</span>
          <TextField
            fullWidth
            label="Password"
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            InputProps={{
              endAdornment: (
                <IconButton onClick={() => setShowPassword((current) => !current)} edge="end" aria-label="Toggle password visibility">
                  {showPassword ? <VisibilityOff /> : <Visibility />}
                </IconButton>
              ),
            }}
          />
        </label>

        {error && <div className="error-box">{error}</div>}
        {infoMessage && <div className="success-box">{infoMessage}</div>}

        <Button type="submit" variant="contained" fullWidth className="login-button" disabled={isLoading}>
          {isLoading ? <><LoadingIndicator label="Logging in" /> LOGGING IN...</> : 'LOG IN'}
        </Button>

        <Button type="button" variant="outlined" color="secondary" fullWidth startIcon={<Google />} onClick={handleGoogleLogin} disabled={isLoading}>
          Continue with Google
        </Button>

        <button type="button" className="text-link" onClick={() => navigate('/forgot-password')}>Forgot Password?</button>
        <div className="divider-row"><span>OR</span></div>
        <Button type="button" variant="outlined" color="secondary" fullWidth onClick={() => navigate('/create-account')}>Create Account</Button>
      </form>
    </div>
  )
}

function OwnerLoginScreen() {
  const navigate = useNavigate()
  const location = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [infoMessage] = useState(location.state?.message || '')
  const [isLoading, setIsLoading] = useState(false)

  const handleLogin = async (event) => {
    event.preventDefault()
    setError('')
    setIsLoading(true)
    try {
      await loginWithRole(email, password, 'owner')
      navigate('/owner-home')
    } catch (loginError) {
      setError(loginError.message || 'Invalid owner credentials.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleGoogleLogin = async () => {
    setError('')
    setIsLoading(true)
    try {
      await loginWithGoogle('owner')
      navigate('/owner-home')
    } catch (loginError) {
      setError(loginError.message || 'Google sign-in was not completed.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/role-selection')} aria-label="Go back"><ArrowBack /></IconButton>
        <img className="brand-logo small" src={appLogo} alt="SJC Canteen" />
      </div>
      <div className="login-illustration gradient-amber"><span>Store Access</span></div>
      <h1>Store Login</h1>
      <p className="subtitle">Manage your canteen orders and inventory</p>

      <form className="login-form" onSubmit={handleLogin}>
        <TextField label="Email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="owner@school.edu.ph" fullWidth />
        <TextField label="Password" type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Enter your password" fullWidth />
        {error && <div className="error-box">{error}</div>}
        {infoMessage && <div className="success-box">{infoMessage}</div>}

        <Button type="submit" variant="contained" fullWidth className="login-button" disabled={isLoading}>
          {isLoading ? <><LoadingIndicator label="Logging in" /> LOGGING IN...</> : 'LOG IN'}
        </Button>

        <Button type="button" variant="outlined" color="secondary" fullWidth startIcon={<Google />} onClick={handleGoogleLogin} disabled={isLoading}>
          Continue with Google
        </Button>

        <Button type="button" variant="text" onClick={() => navigate('/owner-register')}>Create Store Account</Button>
      </form>
    </div>
  )
}

function ForgotPasswordScreen() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')
  const [sent, setSent] = useState(false)

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    try {
      await requestPasswordReset(email)
      setSent(true)
    } catch (resetError) {
      setError(resetError.message || 'Unable to send password reset email.')
    }
  }

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/login')} aria-label="Go back"><ArrowBack /></IconButton>
      </div>
      <h1>Reset Password</h1>
      <p className="subtitle">Enter your email and we will send you a reset link.</p>

      <form className="login-form" onSubmit={handleSubmit}>
        <TextField type="email" label="Email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="you@example.com" fullWidth />
        {error && <div className="error-box">{error}</div>}
        {sent && <div className="success-box">Reset instructions are ready to send for {email}.</div>}
        <Button type="submit" variant="contained" fullWidth>SEND RESET LINK</Button>
      </form>
    </div>
  )
}

function CreateAccountScreen() {
  const navigate = useNavigate()
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setIsLoading(true)

    const form = new FormData(event.currentTarget)
    try {
      await createStudentAccount({
        studentId: String(form.get('studentId') || ''),
        name: String(form.get('name') || ''),
        email: String(form.get('email') || ''),
        password: String(form.get('password') || ''),
      })
      navigate('/login', { state: { message: 'Account created. Check your email and verify your address before signing in.' } })
    } catch (signupError) {
      setError(signupError.message || 'Unable to create the account.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/login')} aria-label="Go back"><ArrowBack /></IconButton>
      </div>
      <h1>Create Account</h1>
      <p className="subtitle">Register your customer account to start ordering.</p>

      <form className="login-form" onSubmit={handleSubmit}>
        <TextField name="name" label="Full Name" placeholder="Your full name" fullWidth />
        <TextField
          name="studentId"
          label="Customer ID"
          placeholder="06-2526-004154"
          fullWidth
          required
          slotProps={{ htmlInput: { inputMode: 'numeric', pattern: '\\d{2}-\\d{4}-\\d{6}', maxLength: 14, title: 'Use the format ##-####-######' } }}
        />
        <TextField name="email" type="email" label="Email" placeholder="yourname.sjc@phinmaed.com" fullWidth />
        <TextField name="password" type="password" label="Password" placeholder="Create a password" fullWidth inputProps={{ minLength: 6 }} />
        {error && <div className="error-box">{error}</div>}
        <Button type="submit" variant="contained" fullWidth disabled={isLoading}>{isLoading ? <><LoadingIndicator label="Creating account" /> CREATING...</> : 'CREATE ACCOUNT'}</Button>
      </form>
    </div>
  )
}

function OwnerRegisterScreen() {
  const navigate = useNavigate()
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setIsLoading(true)

    const form = new FormData(event.currentTarget)
    try {
      await createOwnerAccount({
        name: String(form.get('name') || ''),
        email: String(form.get('email') || ''),
        password: String(form.get('password') || ''),
        storeName: String(form.get('storeName') || ''),
      })
      navigate('/owner-login', { state: { message: 'Store account submitted. An administrator must approve it before you can sign in.' } })
    } catch (signupError) {
      setError(signupError.message || 'Unable to create the store account.')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/owner-login')} aria-label="Go back"><ArrowBack /></IconButton>
      </div>
      <div className="login-illustration gradient-gold"><span>Open Your Store</span></div>
      <h1>Create Store</h1>
      <p className="subtitle">Register your store and start serving customers.</p>

      <form className="login-form" onSubmit={handleSubmit}>
        <TextField name="name" label="Store Representative" placeholder="Your full name" fullWidth />
        <TextField name="storeName" label="Store Name" placeholder="e.g. Green Bowl Canteen" fullWidth />
        <TextField name="email" type="email" label="Email" placeholder="you@example.com" fullWidth />
        <TextField name="password" type="password" label="Password" placeholder="Create a password" fullWidth inputProps={{ minLength: 6 }} />
        {error && <div className="error-box">{error}</div>}
        <Button type="submit" variant="contained" fullWidth disabled={isLoading}>{isLoading ? <><LoadingIndicator label="Creating store" /> CREATING...</> : 'CREATE STORE ACCOUNT'}</Button>
      </form>
    </div>
  )
}

function AdminLoginScreen() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const submit = async (event) => {
    event.preventDefault()
    setLoading(true)
    setError('')
    try {
      await loginWithRole(email, password, 'admin')
      navigate('/admin-home')
    } catch (loginError) {
      setError(loginError.message || 'Admin access was not granted.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="screen-shell login-shell">
      <div className="login-header"><IconButton onClick={() => navigate('/role-selection')} aria-label="Go back"><ArrowBack /></IconButton></div>
      <div className="login-illustration gradient-gold"><span>Administration</span></div>
      <h1>Admin Login</h1>
      <p className="subtitle">Manage accounts and database records.</p>
      <form className="login-form" onSubmit={submit}>
        <TextField label="Admin email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} fullWidth required />
        <TextField label="Password" type="password" value={password} onChange={(event) => setPassword(event.target.value)} fullWidth required />
        {error && <div className="error-box">{error}</div>}
        <Button type="submit" variant="contained" fullWidth disabled={loading}>{loading ? 'LOGGING IN...' : 'ADMIN LOGIN'}</Button>
      </form>
    </div>
  )
}

function AdminNavigationScreen() {
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [error, setError] = useState('')
  const [editingUser, setEditingUser] = useState(null)
  const [editForm, setEditForm] = useState({ name: '', email: '', role: 'student', studentId: '', storeName: '' })
  const [isSaving, setIsSaving] = useState(false)

  useEffect(() => {
    if (!auth) return undefined
    let unsubscribeUsers
    const unsubscribeAuth = onAuthStateChanged(auth, async (user) => {
      unsubscribeUsers?.()
      if (!user) {
        navigate('/admin-login', { replace: true })
        return
      }
      const profile = await getUserProfile(user.uid)
      if (profile?.role !== 'admin') {
        navigate('/role-selection', { replace: true })
        return
      }
      unsubscribeUsers = subscribeToAllUsers(setUsers, (userError) => setError(formatFirebaseError(userError)))
    })
    return () => {
      unsubscribeAuth()
      unsubscribeUsers?.()
    }
  }, [navigate])

  const removeUser = async (user) => {
    if (!window.confirm(`Delete the ${user.role} account for ${user.email || user.id}? This also revokes Firebase Auth access.`)) return
    try {
      await deleteUserAccount(user.id)
      setError('')
    } catch (deleteError) {
      setError(formatFirebaseError(deleteError))
    }
  }

  const setOwnerApproval = async (user, status) => {
    try {
      await updateUserProfile(user.id, { status })
      setError('')
    } catch (approvalError) {
      setError(formatFirebaseError(approvalError))
    }
  }

  const startEditing = (user) => {
    setEditingUser(user)
    setEditForm({
      name: user.name || '',
      email: user.email || '',
      role: user.role || 'student',
      studentId: user.studentId || '',
      storeName: user.storeName || '',
    })
    setError('')
  }

  const saveUser = async () => {
    if (!editingUser) return
    setIsSaving(true)
    try {
      const profile = {
        name: editForm.name.trim(),
        email: editForm.email.trim(),
        role: editForm.role,
      }
      if (editForm.role === 'student') profile.studentId = editForm.studentId.trim()
      if (editForm.role === 'owner') profile.storeName = editForm.storeName.trim()
      await updateUserProfile(editingUser.id, profile)
      setEditingUser(null)
      setError('')
    } catch (updateError) {
      setError(formatFirebaseError(updateError))
    } finally {
      setIsSaving(false)
    }
  }

  const logoutAdmin = async () => {
    await logoutUser()
    window.location.href = '/admin-login'
  }

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">ADMINISTRATION</span><h1>Account Management</h1><p>Review active student and owner profiles.</p></div>
      {error && <div className="error-box">{error}</div>}
      <div className="order-list">
        {users.filter((user) => user.role !== 'admin').map((user) => (
          <article className="owner-order" key={user.id}>
            <div className="order-heading"><strong>{user.name || user.email || 'Account'}</strong><span className="status">{user.role}</span></div>
            <p>{user.email || 'No email recorded'}</p>
            <p>{user.role === 'owner' ? user.storeName || 'Store' : user.studentId || 'Customer account'}</p>
            {user.role === 'owner' && <p>Approval: {user.status || 'pending'}</p>}
            <div className="header-action-group">
              <button className="secondary-button" onClick={() => startEditing(user)}>EDIT DATA</button>
              {user.role === 'owner' && user.status !== 'approved' && <button className="primary-button" onClick={() => setOwnerApproval(user, 'approved')}>APPROVE OWNER</button>}
              {user.role === 'owner' && user.status === 'approved' && <button className="secondary-button" onClick={() => setOwnerApproval(user, 'rejected')}>REJECT OWNER</button>}
              <button className="secondary-button" onClick={() => removeUser(user)}>DELETE ACCOUNT</button>
            </div>
          </article>
        ))}
      </div>
      <Dialog open={Boolean(editingUser)} onClose={() => !isSaving && setEditingUser(null)} fullWidth maxWidth="sm">
        <DialogTitle>Edit account data</DialogTitle>
        <DialogContent>
          <TextField margin="dense" label="Full name" value={editForm.name} onChange={(event) => setEditForm({ ...editForm, name: event.target.value })} fullWidth />
          <TextField margin="dense" label="Email" type="email" value={editForm.email} onChange={(event) => setEditForm({ ...editForm, email: event.target.value })} fullWidth />
          <TextField margin="dense" select label="Role" value={editForm.role} onChange={(event) => setEditForm({ ...editForm, role: event.target.value })} fullWidth>
            <MenuItem value="student">Student</MenuItem>
            <MenuItem value="owner">Owner</MenuItem>
            <MenuItem value="admin">Admin</MenuItem>
          </TextField>
          {editForm.role === 'student' && <TextField margin="dense" label="Customer ID" value={editForm.studentId} onChange={(event) => setEditForm({ ...editForm, studentId: event.target.value })} fullWidth />}
          {editForm.role === 'owner' && <TextField margin="dense" label="Store name" value={editForm.storeName} onChange={(event) => setEditForm({ ...editForm, storeName: event.target.value })} fullWidth />}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditingUser(null)} disabled={isSaving}>Cancel</Button>
          <Button onClick={saveUser} variant="contained" disabled={isSaving}>{isSaving ? 'Saving...' : 'Save changes'}</Button>
        </DialogActions>
      </Dialog>
      <div className="header-action-group">
        <button className="secondary-button compact-action" onClick={logoutAdmin}>LOG OUT</button>
      </div>
      <AssistantDrawer />
    </div>
  )
}

function StudentNavigationScreen() {
  const [tab, setTab] = useState('Stores')

  const views = {
    Stores: <StudentStoreBrowserScreen />,
    Orders: <StudentOrdersScreen history={false} />,
    History: <StudentOrdersScreen history />,
    Profile: <StudentProfileScreen />,
  }

  return (
    <div className="app-shell">
      <StudentNotificationBanner />
      {views[tab]}
      <AssistantDrawer />
      <nav className="bottom-nav student-nav">
        {['Stores', 'Orders', 'History', 'Profile'].map((item) => (
          <Button key={item} className={tab === item ? 'nav-item active' : 'nav-item'} variant="text" onClick={() => setTab(item)}>{item}</Button>
        ))}
      </nav>
    </div>
  )
}

function StudentNotificationBanner() {
  const navigate = useNavigate()
  const [notification, setNotification] = useState(null)

  useEffect(() => {
    if (!auth) return undefined

    let unsubscribeNotifications
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      unsubscribeNotifications?.()
      if (!user) return
      unsubscribeNotifications = subscribeToNotifications(user.uid, (notifications) => {
        const unread = notifications.find((item) => !item.isRead)
        setNotification(unread || null)
      }, () => {})
    })

    return () => {
      unsubscribeAuth()
      unsubscribeNotifications?.()
    }
  }, [])

  if (!notification) return null

  const dismiss = async () => {
    setNotification(null)
    await markNotificationRead(notification.id)
  }

  return (
    <div className="live-notification" role="status">
      <div>
        <strong>{notification.title || 'Order update'}</strong>
        <span>{notification.message}</span>
      </div>
      <button type="button" onClick={() => navigate('/notifications')}>VIEW</button>
      <button type="button" className="notification-dismiss" onClick={dismiss} aria-label="Dismiss notification">×</button>
    </div>
  )
}

function StudentStoreBrowserScreen() {
  const navigate = useNavigate()
  const [stores, setStores] = useState([])
  const [selectedStoreId, setSelectedStoreId] = useState('')
  const [menuItems, setMenuItems] = useState([])
  const [cart, setCart] = useState([])
  const [cartOpen, setCartOpen] = useState(false)
  const [paymentMethod, setPaymentMethod] = useState('Cash on Pickup')
  const [error, setError] = useState('')
  const [isOrdering, setIsOrdering] = useState(false)
  const [orderMessage, setOrderMessage] = useState('')

  useEffect(() => {
    const unsubscribe = subscribeToOwnerStores((ownerStores) => {
      setStores(ownerStores)
      if (!selectedStoreId && ownerStores.length > 0) {
        setSelectedStoreId(ownerStores[0].id)
      }
    }, (storeError) => setError(storeError.message))
    return unsubscribe
  }, [selectedStoreId])

  useEffect(() => {
    if (!selectedStoreId) {
      setMenuItems([])
      return undefined
    }

    const unsubscribe = subscribeToFoodItems(selectedStoreId, (items) => {
      setMenuItems(items.filter((item) => item.isAvailable !== false))
    }, (foodError) => setError(formatFirebaseError(foodError)))

    return unsubscribe
  }, [selectedStoreId])

  const selectedStore = useMemo(() => stores.find((store) => store.id === selectedStoreId) || null, [stores, selectedStoreId])
  const totalCartValue = cart.reduce((sum, item) => sum + Number(item.price || 0), 0)

  const addToCart = (food) => {
    setCart((items) => [...items, { ...food, storeId: selectedStoreId }])
    setOrderMessage('')
  }

  const selectStore = (storeId) => {
    if (storeId !== selectedStoreId && cart.length > 0) {
      setCart([])
      setCartOpen(false)
      setOrderMessage('Your cart was cleared because you switched stores.')
    }
    setSelectedStoreId(storeId)
  }

  const handleCheckout = async () => {
    if (!selectedStoreId) {
      setOrderMessage('Choose a store to place an order.')
      return
    }
    if (cart.length === 0) {
      setOrderMessage('Your cart is empty.')
      return
    }

    setIsOrdering(true)
    setOrderMessage('')
    try {
      const orderId = await placeStudentOrder(cart, paymentMethod, selectedStoreId)
      setCart([])
      setCartOpen(false)
      setOrderMessage(`Ticket #${orderId.slice(-6)} placed successfully from ${selectedStore?.storeName || 'the selected store'}.`)
    } catch (orderError) {
      setOrderMessage(orderError.message || 'Unable to place order.')
    } finally {
      setIsOrdering(false)
    }
  }

  return (
    <div className="screen-shell">
      <div className="student-header">
        <div>
          <span className="eyebrow">SJC CANTEEN</span>
          <h1>Browse Stores</h1>
        </div>
        <div className="avatar">S</div>
      </div>

      <div className="promo-panel">
        <img className="promo-panel-image" src={canteenImage} alt="School canteen dining hall" />
        <div className="promo-panel-content">
          <span>Community Kitchens</span>
          <strong>{stores.length} active stores nearby</strong>
          <small>Choose a canteen and order fresh meals.</small>
        </div>
        <div className="promo-count-badge" aria-label={`${stores.length} active stores`}>
          <strong>{stores.length}</strong>
          <span>stores<br />open</span>
        </div>
      </div>

      <div className="header-action-group student-action-group">
        <button type="button" className="secondary-button compact-action" onClick={() => navigate('/notifications')}>
          <NotificationsNone className="action-icon" aria-hidden="true" />
          <span>NOTIFICATIONS &amp; ORDER HISTORY</span>
          <History className="action-icon" aria-hidden="true" />
        </button>
        <button type="button" className="secondary-button compact-action" onClick={async () => {
          if (!auth?.currentUser || !window.confirm('Clear your order history?')) return
          try {
            await clearStudentOrders(auth.currentUser.uid)
            setOrderMessage('Your orders were cleared.')
          } catch (clearError) {
            setOrderMessage(formatFirebaseError(clearError))
          }
        }}>
          <DeleteSweep className="action-icon" aria-hidden="true" />
          <span>CLEAR ORDERS</span>
        </button>
      </div>

      {error && <div className="error-box">{error}</div>}

      <div className="store-list">
        {stores.length === 0 && <div className="empty-panel">No stores are available yet. New owners will appear here as soon as they register.</div>}
        {stores.map((store) => (
          <button type="button" key={store.id} className={selectedStoreId === store.id ? 'store-tile active' : 'store-tile'} onClick={() => selectStore(store.id)}>
            <div className="store-tile-icon" aria-hidden="true"><Storefront /></div>
            <div className="store-tile-copy">
              <strong>{store.storeName || 'Store'}</strong>
              <span>{store.name || 'Owner'}</span>
            </div>
          </button>
        ))}
      </div>

      {selectedStore && (
        <>
          <div className="section-heading">
            <div>
              <h2>{selectedStore.storeName}</h2>
              <p>{menuItems.length} menu items available</p>
            </div>
            <Button className="cart-button" variant="contained" color="primary" onClick={() => setCartOpen((current) => !current)} aria-label="View cart">Cart ({cart.length})</Button>
          </div>

          {cartOpen && cart.length > 0 && (
            <div className="cart-panel">
              <strong>Your cart</strong>
              {cart.map((item, index) => (
                <div className="cart-line" key={`${item.id || item.name}-${index}`}>
                  <span>{item.title || item.name}</span>
                  <span>PHP {Number(item.price || 0)}</span>
                </div>
              ))}
              <div className="cart-total"><strong>Total</strong><strong>PHP {totalCartValue}</strong></div>
              <div className="payment-methods">
                <strong>Payment method</strong>
                <Button className={paymentMethod === 'Cash on Pickup' ? 'payment-option selected' : 'payment-option'} variant={paymentMethod === 'Cash on Pickup' ? 'contained' : 'outlined'} onClick={() => setPaymentMethod('Cash on Pickup')}>Cash on Pickup</Button>
                <Button className={paymentMethod === 'GCash' ? 'payment-option selected' : 'payment-option'} variant={paymentMethod === 'GCash' ? 'contained' : 'outlined'} onClick={() => setPaymentMethod('GCash')}>GCash</Button>
              </div>
              <Button variant="contained" fullWidth onClick={handleCheckout} disabled={isOrdering}>{isOrdering ? <><LoadingIndicator label="Placing order" /> PLACING ORDER...</> : 'PLACE ORDER'}</Button>
            </div>
          )}

          {orderMessage && <div className="success-box order-message">{orderMessage}</div>}

          <div className="food-grid">
            {menuItems.length === 0 && <div className="empty-panel full-width-empty">This store has not added menu items yet. Inventory opens once the owner has uploaded their products.</div>}
            {menuItems.map((food) => (
              <article className="food-card" key={food.id}>
                <div className="food-card-text-only" aria-hidden="true"><FoodCategoryIcon category={food.category} /></div>
                <div className="food-card-content">
                  <span>{food.category}</span>
                  <h3>{food.title || food.name}</h3>
                  <p>{food.description || 'Freshly prepared at this store.'}</p>
                  <div className="food-card-footer">
                    <strong>PHP {Number(food.price || 0)}</strong>
                    <IconButton className="add-button" color="primary" onClick={() => addToCart(food)} aria-label={`Add ${food.title || food.name} to cart`}><AddShoppingCart /></IconButton>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </>
      )}
    </div>
  )
}

function StudentOrdersScreen({ history }) {
  const [orders, setOrders] = useState([])
  const [storeQueues, setStoreQueues] = useState({})
  const [error, setError] = useState('')
  const [now, setNow] = useState(() => Date.now())

  useEffect(() => {
    if (!auth) return undefined

    let unsubscribeOrders
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      unsubscribeOrders?.()
      if (!user) return
      unsubscribeOrders = subscribeToStudentOrders(user.uid, setOrders, (orderError) => setError(orderError.message))
    })

    return () => {
      unsubscribeAuth()
      unsubscribeOrders?.()
    }
  }, [])

  useEffect(() => {
    if (history || orders.length === 0) {
      setStoreQueues({})
      return undefined
    }

    const storeIds = [...new Set(orders.map((order) => order.storeId).filter(Boolean))]
    const queueData = {}
    const unsubscribers = storeIds.map((storeId) => subscribeToStoreActiveOrders(storeId, (queue) => {
      queueData[storeId] = queue
      setStoreQueues({ ...queueData })
    }, (queueError) => setError(formatFirebaseError(queueError))))

    return () => unsubscribers.forEach((unsubscribe) => unsubscribe())
  }, [history, orders])

  useEffect(() => {
    if (history) return undefined
    const timer = window.setInterval(() => setNow(Date.now()), 60000)
    return () => window.clearInterval(timer)
  }, [history])

  const activeStatuses = ['Pending', 'Accepted', 'Preparing', 'Ready for Pickup']
  const visibleOrders = orders.filter((order) => (history ? !activeStatuses.includes(order.status) : activeStatuses.includes(order.status)))
  const clearOrders = async () => {
    if (!auth?.currentUser || !window.confirm('Clear your order history?')) return
    try {
      await clearStudentOrders(auth.currentUser.uid)
      setOrders([])
    } catch (clearError) {
      setError(formatFirebaseError(clearError))
    }
  }

  const getWaitEstimate = (order) => {
    if (order.status === 'Ready for Pickup') return { minutes: 0, queueAhead: 0, ready: true }

    const queue = storeQueues[order.storeId] || []
    const orderTime = order.timestamp?.toMillis?.() || now
    const queueAhead = queue.filter((queuedOrder) => queuedOrder.id !== order.id && (queuedOrder.timestamp?.toMillis?.() || now) < orderTime).length
    const itemMinutes = (order.cartItems || []).reduce((total, item) => {
      const categoryMinutes = item.category === 'Meals' ? 5 : item.category === 'Snacks' ? 2 : 1
      return total + categoryMinutes * Number(item.quantity || 1)
    }, 0)
    const estimatedMinutes = 5 + itemMinutes + queueAhead * 5
    const elapsedMinutes = Math.max(0, Math.floor((now - orderTime) / 60000))

    return { minutes: Math.max(0, estimatedMinutes - elapsedMinutes), queueAhead, ready: false }
  }

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading">
        <span className="eyebrow">SJC CANTEEN</span>
        <h1>{history ? 'Order History' : 'Active Orders'}</h1>
        <p>{history ? 'Your previous canteen orders.' : 'Track your meals from order to pickup.'}</p>
      </div>
      <div className="header-action-group">
        <button className="secondary-button compact-action" onClick={clearOrders}>CLEAR ORDERS</button>
      </div>
      {error && <div className="error-box">{error}</div>}
      <div className="order-list">
        {visibleOrders.length === 0 && <div className="empty-panel">No {history ? 'past' : 'active'} orders yet.</div>}
        {visibleOrders.map((order) => (
          <article className="student-order" key={order.id}>
            <div className="order-heading"><strong>{order.storeName || 'Store'}</strong><span className="status">{order.status}</span></div>
            <div className="ticket-row"><strong>Ticket #{order.ticketNumber || order.id.slice(-6)}</strong><span>{history ? 'Completed order' : 'In queue'}</span></div>
            {!history && (() => {
              const estimate = getWaitEstimate(order)
              return <><OrderProgressTracker status={order.status} /><div className="wait-time-row"><strong>{estimate.ready ? 'Ready for pickup' : `${estimate.minutes} min estimated wait`}</strong><span>{estimate.ready ? 'Come to the counter' : `${estimate.queueAhead} ticket${estimate.queueAhead === 1 ? '' : 's'} ahead`}</span></div></>
            })()}
            <p>{order.itemsDescription || 'Order items'}</p>
            <p>PHP {Number(order.total || 0)} · {order.paymentMethod || 'Payment not recorded'}</p>
            <small>{order.studentId || ''}</small>
          </article>
        ))}
      </div>
    </div>
  )
}

function StudentProfileScreen() {
  const navigate = useNavigate()
  const [profile, setProfile] = useState(null)
  const [name, setName] = useState('')
  const [message, setMessage] = useState('')
  const [authReady, setAuthReady] = useState(false)

  useEffect(() => {
    if (!auth) return undefined
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setAuthReady(true)
      if (!user) {
        navigate('/login', { replace: true })
        return
      }
      const data = await getUserProfile(user.uid)
      setProfile(data)
      setName(data?.name || user.displayName || '')
    })
    return unsubscribe
  }, [navigate])

  const saveProfile = async () => {
    if (!auth?.currentUser || !name.trim()) return
    await updateUserProfile(auth.currentUser.uid, { name: name.trim() })
    setMessage('Profile updated.')
  }

  const logoutStudent = async () => {
    try {
      await logoutUser()
      navigate('/login', { replace: true })
    } catch (logoutError) {
      setMessage(logoutError.message || 'Unable to log out. Please try again.')
    }
  }

  if (!authReady) {
    return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">ACCOUNT</span><h1>Customer Profile</h1><p>Loading your account...</p></div></div>
  }

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">ACCOUNT</span><h1>Customer Profile</h1><p>Manage your account details and preferences.</p></div>
      <div className="profile-card">
        <div className="avatar large">{(name || 'S').charAt(0).toUpperCase()}</div>
        <label><span>Full Name</span><input value={name} onChange={(event) => setName(event.target.value)} /></label>
        <label><span>Email</span><input value={profile?.email || auth?.currentUser?.email || ''} disabled /></label>
        <label><span>Customer ID</span><input value={profile?.studentId || ''} disabled /></label>
        <button className="secondary-button" onClick={() => navigate('/notifications')}>NOTIFICATIONS</button>
        <button className="primary-button" onClick={saveProfile}>SAVE PROFILE</button>
        {message && <div className="success-box">{message}</div>}
        <button className="secondary-button" onClick={logoutStudent}>LOG OUT</button>
      </div>
    </div>
  )
}

function NotificationsScreen() {
  const [notifications, setNotifications] = useState([])
  const [error, setError] = useState('')

  useEffect(() => {
    if (!auth) return undefined

    let unsubscribeNotifications
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      unsubscribeNotifications?.()
      if (user) unsubscribeNotifications = subscribeToNotifications(user.uid, setNotifications, (notificationError) => setError(formatFirebaseError(notificationError)))
    })

    return () => {
      unsubscribeAuth()
      unsubscribeNotifications?.()
    }
  }, [])

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">UPDATES</span><h1>Notifications</h1><p>Order updates and canteen announcements.</p></div>
      {error && <div className="error-box">{error}</div>}
      <div className="order-list">
        {notifications.length === 0 && <div className="empty-panel">No notifications yet.</div>}
        {notifications.map((notification) => (
          <article className="student-order" key={notification.id} onClick={() => markNotificationRead(notification.id)}>
            <div className="order-heading"><strong>{notification.title}</strong><span className="status">{notification.isRead ? 'Read' : 'New'}</span></div>
            <p>{notification.message}</p>
          </article>
        ))}
      </div>
    </div>
  )
}

function OwnerNavigationScreen() {
  const [tab, setTab] = useState('Dashboard')
  const views = {
    Dashboard: <OwnerDashboardScreen />,
    Orders: <OwnerOrdersScreen />,
    Inventory: <OwnerInventoryScreen />,
    Profile: <OwnerProfileScreen />,
  }

  return (
    <div className="app-shell">
      {views[tab]}
      <AssistantDrawer />
      <nav className="bottom-nav owner-nav">
        {['Dashboard', 'Orders', 'Inventory', 'Profile'].map((item) => (
          <Button key={item} className={tab === item ? 'nav-item active' : 'nav-item'} variant="text" onClick={() => setTab(item)}>{item}</Button>
        ))}
      </nav>
    </div>
  )
}

function OwnerDashboardScreen() {
  const navigate = useNavigate()
  const [orders, setOrders] = useState([])
  const [items, setItems] = useState([])
  const [profile, setProfile] = useState(null)
  const [error, setError] = useState('')

  useEffect(() => {
    if (!auth) {
      setError('Firebase is not configured.')
      return undefined
    }

    let unsubscribeOrders
    let unsubscribeItems
    const unsubscribeAuth = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        navigate('/owner-login', { replace: true })
        return
      }

      const profileData = await getUserProfile(user.uid)
      if (profileData?.role !== 'owner') {
        navigate('/owner-login', { replace: true })
        return
      }

      setProfile(profileData)
      unsubscribeOrders = subscribeToAllOrders(user.uid, (allOrders) => {
        setOrders(allOrders)
      }, (orderError) => setError(orderError.message))

      unsubscribeItems = subscribeToFoodItems(user.uid, (foodItems) => {
        setItems(foodItems)
      }, (foodError) => setError(foodError.message))
    })

    return () => {
      unsubscribeAuth()
      unsubscribeOrders?.()
      unsubscribeItems?.()
    }
  }, [navigate])

  const revenue = orders.reduce((total, order) => total + Number(order.total || 0), 0)
  const pendingCount = orders.filter((order) => order.status === 'Pending').length
  const availableItems = items.filter((item) => item.isAvailable !== false).length
  const clearOrders = async () => {
    if (!auth?.currentUser || !window.confirm('Clear all orders for this store?')) return
    try {
      await clearStoreOrders(auth.currentUser.uid)
      setOrders([])
    } catch (clearError) {
      setError(formatFirebaseError(clearError))
    }
  }

  return (
    <div className="screen-shell">
      <div className="store-hero-card">
        <div className="store-hero-copy">
          <span className="eyebrow">SJC CANTEEN</span>
          <h1>{profile?.storeName || 'Your Store'}</h1>
          <p>Manage menus, inventory, and each active order in one place.</p>
        </div>
        <div className="store-hero-icon" aria-hidden="true"><Storefront /></div>
      </div>

      {error && <div className="error-box">{error}</div>}

      <div className="metric-grid owner-metrics">
        <div className="metric-card"><span>Revenue</span><strong>PHP {revenue}</strong></div>
        <div className="metric-card"><span>Orders</span><strong>{orders.length}</strong></div>
        <div className="metric-card"><span>Pending</span><strong>{pendingCount}</strong></div>
        <div className="metric-card"><span>Menu Items</span><strong>{availableItems}</strong></div>
      </div>
      <div className="header-action-group">
        <button className="secondary-button compact-action" onClick={clearOrders}>CLEAR ORDERS</button>
      </div>

      <div className="owner-order-list">
        <div className="section-heading"><h2>Incoming Orders</h2><span>{orders.length} total</span></div>
        {orders.length === 0 && <div className="empty-panel">No orders yet. Add items to your inventory and students can start ordering here.</div>}
        {orders.map((order) => (
          <article className="owner-order" key={order.id}>
            <div className="order-heading"><strong>Ticket #{order.ticketNumber || order.id.slice(-6)}</strong><span className={`status status-${String(order.status).toLowerCase()}`}>{order.status}</span></div>
            <p>Customer: {order.studentName || 'Customer'}</p>
            <p>{order.itemsDescription}</p>
            <div className="order-heading"><strong>PHP {Number(order.total || 0)}</strong><span>{order.paymentMethod || 'Payment not recorded'}</span></div>
            {order.status === 'Pending' && <button className="primary-button" onClick={() => updateOrderStatus(order.id, 'Accepted')}>ACCEPT ORDER</button>}
          </article>
        ))}
      </div>
    </div>
  )
}

function OwnerOrdersScreen() {
  const [orders, setOrders] = useState([])
  const [error, setError] = useState('')

  useEffect(() => {
    if (!auth) return undefined

    let unsubscribeOrders
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      unsubscribeOrders?.()
      if (!user) return
      unsubscribeOrders = subscribeToAllOrders(user.uid, (allOrders) => {
        setOrders(allOrders)
      }, (orderError) => setError(formatFirebaseError(orderError)))
    })

    return () => {
      unsubscribeAuth()
      unsubscribeOrders?.()
    }
  }, [])

  const advance = async (order) => {
    const nextStatus = order.status === 'Pending' ? 'Accepted' : order.status === 'Accepted' ? 'Preparing' : order.status === 'Preparing' ? 'Ready for Pickup' : 'Completed'
    await updateOrderStatus(order.id, nextStatus)
  }

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">OPERATIONS</span><h1>Orders</h1><p>Review and advance student orders.</p></div>
      {error && <div className="error-box">{error}</div>}
      <div className="order-list">
        {orders.length === 0 && <div className="empty-panel">No orders yet.</div>}
        {orders.map((order) => (
          <article className="owner-order" key={order.id}>
            <div className="order-heading"><strong>Ticket #{order.ticketNumber || order.id.slice(-6)}</strong><span className="status">{order.status}</span></div>
            <p>Customer: {order.studentName || 'Customer'}</p>
            <p>{order.itemsDescription}</p>
            <div className="order-heading"><strong>PHP {Number(order.total || 0)}</strong><span>{order.paymentMethod || 'Payment not recorded'}</span></div>
            {order.status !== 'Completed' && <button className="primary-button" onClick={() => advance(order)}>MARK {order.status === 'Pending' ? 'ACCEPTED' : order.status === 'Accepted' ? 'PREPARING' : order.status === 'Preparing' ? 'READY' : 'COMPLETED'}</button>}
          </article>
        ))}
      </div>
    </div>
  )
}

function OwnerInventoryScreen() {
  const [items, setItems] = useState([])
  const [message, setMessage] = useState('')
  const [isSaving, setIsSaving] = useState(false)
  const [editingId, setEditingId] = useState('')
  const [form, setForm] = useState({ title: '', description: '', price: '', category: 'Meals' })

  useEffect(() => {
    if (!auth) return undefined

    let unsubscribeItems
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      unsubscribeItems?.()
      if (!user) return
      unsubscribeItems = subscribeToFoodItems(user.uid, setItems, (foodError) => {
        setMessage(formatFirebaseError(foodError))
      })
    })

    return () => {
      unsubscribeAuth()
      unsubscribeItems?.()
    }
  }, [])

  const handleAddItem = async (event) => {
    event.preventDefault()
    if (!auth?.currentUser) return

    try {
      setMessage('')
      setIsSaving(true)

      if (editingId) {
        await updateFoodItem(editingId, form)
      } else {
        await addFoodItem(form, auth.currentUser.uid)
      }
      setForm({ title: '', description: '', price: '', category: 'Meals' })
      setEditingId('')
      setMessage(editingId ? 'Menu item updated.' : 'Menu item added.')
    } catch (errorMessage) {
      setMessage(formatFirebaseError(errorMessage, 'Unable to add the item.'))
    } finally {
      setIsSaving(false)
    }
  }

  const startEditing = (item) => {
    setEditingId(item.id)
    setForm({
      title: item.title || '',
      description: item.description || '',
      price: String(item.price || ''),
      category: item.category || 'Meals',
    })
    setMessage('')
  }

  const cancelEditing = () => {
    setEditingId('')
    setForm({ title: '', description: '', price: '', category: 'Meals' })
    setMessage('')
  }

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">CATALOG</span><h1>Inventory</h1><p>Add menu items and control availability.</p></div>
      <form className="inventory-form" onSubmit={handleAddItem}>
        <input placeholder="Item name" value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} required />
        <textarea placeholder="Short food description" value={form.description} onChange={(event) => setForm({ ...form, description: event.target.value })} rows="3" required />
        <input type="number" min="0" placeholder="Price" value={form.price} onChange={(event) => setForm({ ...form, price: event.target.value })} required />
        <select value={form.category} onChange={(event) => setForm({ ...form, category: event.target.value })}>
          <option>Meals</option>
          <option>Snacks</option>
          <option>Drinks</option>
        </select>

        {message && <div className="success-box">{message}</div>}
        <button className="primary-button" type="submit" disabled={isSaving}>{isSaving ? <><LoadingIndicator label="Saving item" /> SAVING...</> : editingId ? 'UPDATE ITEM' : 'ADD ITEM'}</button>
        {editingId && <button className="secondary-button" type="button" onClick={cancelEditing}>CANCEL EDIT</button>}
      </form>

      <div className="order-list">
        {items.map((item) => (
          <article className="owner-order" key={item.id}>
            <div className="owner-item-card">
              <div className="owner-item-text-only" aria-hidden="true"><FoodCategoryIcon category={item.category} /></div>
              <div className="owner-item-copy">
                <div className="order-heading"><strong>{item.title}</strong><span>PHP {Number(item.price || 0)}</span></div>
                <p>{item.description || 'No description provided.'}</p>
                <p>{item.category} · {item.isAvailable === false ? 'Unavailable' : 'Available'}</p>
              </div>
            </div>
            <button className="secondary-button" onClick={() => startEditing(item)}>EDIT ITEM</button>
            <button className="secondary-button" onClick={() => toggleFoodAvailability(item.id, item.isAvailable !== false)}>{item.isAvailable === false ? 'MAKE AVAILABLE' : 'MARK SOLD OUT'}</button>
            <button className="text-link" onClick={() => deleteFoodItem(item.id)}>DELETE ITEM</button>
          </article>
        ))}
      </div>
    </div>
  )
}

function OwnerProfileScreen() {
  const navigate = useNavigate()
  const [profile, setProfile] = useState(null)

  useEffect(() => {
    if (!auth?.currentUser) return
    getUserProfile(auth.currentUser.uid).then(setProfile)
  }, [])

  const logoutOwner = async () => {
    await logoutUser()
    navigate('/owner-login', { replace: true })
  }

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">ACCOUNT</span><h1>Store Profile</h1><p>Manage your SJC Canteen store account.</p></div>
      <div className="profile-card">
        <div className="avatar large">{(profile?.storeName || 'O').charAt(0).toUpperCase()}</div>
        <h2>{profile?.storeName || 'Store'}</h2>
        <p>{profile?.email || ''}</p>
        <p>{profile?.name || 'Owner'}</p>
        <button className="secondary-button" onClick={logoutOwner}>LOG OUT</button>
      </div>
    </div>
  )
}

export default App
