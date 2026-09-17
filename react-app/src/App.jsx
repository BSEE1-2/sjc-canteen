import { BrowserRouter, Routes, Route, useNavigate } from 'react-router-dom'
import { useState } from 'react'
import { useEffect } from 'react'
import { onAuthStateChanged } from 'firebase/auth'
import { Button, IconButton, InputAdornment, TextField } from '@mui/material'
import { AddShoppingCart, ArrowBack, Google, Visibility, VisibilityOff } from '@mui/icons-material'
import foodOne from '../../assets/images/food_1.png'
import foodTwo from '../../assets/images/food_2.png'
import foodThree from '../../assets/images/food_3.png'
import onboardingImage from '../../assets/images/onboarding_1.png'
import studentsImage from '../../assets/images/students.jpg'
import canteenImage from '../../assets/images/canteen.jpg'
import logoApp from '../../assets/images/logoapp.png'
import { addFoodItem, createStudentAccount, deleteFoodItem, getUserProfile, loginWithGoogle, loginWithRole, logout as logoutUser, markNotificationRead, placeStudentOrder, requestPasswordReset, subscribeToAllOrders, subscribeToFoodItems, subscribeToNotifications, subscribeToStudentOrders, toggleFoodAvailability, updateOrderStatus, updateUserProfile } from './services/firebaseService'
import { auth } from './firebase'
import './App.css'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<OnboardingScreen />} />
        <Route path="/role-selection" element={<RoleSelectionScreen />} />
        <Route path="/login" element={<StudentLoginScreen />} />
        <Route path="/owner-login" element={<OwnerLoginScreen />} />
        <Route path="/notifications" element={<NotificationsScreen />} />
        <Route path="/forgot-password" element={<ForgotPasswordScreen />} />
        <Route path="/create-account" element={<CreateAccountScreen />} />
        <Route path="/student-home" element={<StudentNavigationScreen />} />
        <Route path="/owner-home" element={<OwnerNavigationScreen />} />
      </Routes>
    </BrowserRouter>
  )
}

function OnboardingScreen() {
  const navigate = useNavigate()
  const [page, setPage] = useState(0)
  const slides = [
    {
      title: 'Order from anywhere',
      description: 'Skip the line and order your favorite meals right from your classroom.',
      image: onboardingImage,
    },
    {
      title: 'Track in real time',
      description: 'Get notified as soon as your order is being prepared and ready for pickup.',
      image: studentsImage,
    },
    {
      title: 'Empowering canteens',
      description: 'A powerful dashboard for owners to manage orders and inventory with ease.',
      image: canteenImage,
    },
  ]
  const slide = slides[page]

  return (
    <div className="screen-shell onboarding-shell">
      <div className="brand-row">
        <img className="brand-logo" src={logoApp} alt="SJC Canteen" />
        <span>SJC Canteen</span>
        {page < slides.length - 1 && <Button className="skip-button" variant="text" onClick={() => navigate('/role-selection')}>Skip</Button>}
      </div>

      <div className="onboarding-card">
        <img className="onboarding-image" src={slide.image} alt="" />
        <h1>{slide.title}</h1>
        <p>{slide.description}</p>
      </div>

      <div className="onboarding-dots" aria-label={`Introduction step ${page + 1} of ${slides.length}`}>
        {slides.map((item, index) => <button key={item.title} className={index === page ? 'onboarding-dot active' : 'onboarding-dot'} onClick={() => setPage(index)} aria-label={`Go to step ${index + 1}`} />)}
      </div>
      <div className="onboarding-actions">
        <Button variant="contained" fullWidth onClick={() => page === slides.length - 1 ? navigate('/role-selection') : setPage((current) => current + 1)}>
          {page === slides.length - 1 ? 'Get Started' : 'Continue'}
        </Button>
      </div>
    </div>
  )
}

function RoleSelectionScreen() {
  const navigate = useNavigate()

  return (
    <div className="screen-shell">
      <div className="header-row">
        <img className="brand-logo small" src={logoApp} alt="SJC Canteen" />
        <h2>SJC Canteen</h2>
      </div>

      <div className="role-select-wrap">
        <div className="role-card">
          <div className="role-emoji">🎓</div>
          <h3>Student</h3>
          <p>Browse daily menus and pre-order your meals in minutes.</p>
          <Button variant="contained" fullWidth onClick={() => navigate('/login')}>
            I am a Student
          </Button>
        </div>

        <div className="role-card">
          <div className="role-emoji">🏪</div>
          <h3>Canteen Owner</h3>
          <p>Manage inventory, orders, and student payments from one place.</p>
          <Button variant="outlined" color="secondary" fullWidth onClick={() => navigate('/owner-login')}>
            I am an Owner
          </Button>
        </div>
      </div>
    </div>
  )
}

function StudentLoginScreen() {
  const navigate = useNavigate()
  const [studentId, setStudentId] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)

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

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/role-selection')} aria-label="Go back"><ArrowBack /></IconButton>
        <img className="brand-logo small" src={logoApp} alt="SJC Canteen" />
      </div>

      <div className="login-illustration gradient-amber">
        <span>Student Login</span>
      </div>

      <h1>Welcome Back!</h1>
      <p className="subtitle">Log in to your school ordering account</p>

      <form className="login-form" onSubmit={handleLogin}>
        <label>
          <span>Student ID</span>
          <TextField
            fullWidth
            label="Student ID or Email"
            placeholder="e.g. 06-2425-000000"
            value={studentId}
            onChange={(e) => setStudentId(e.target.value)}
          />
        </label>

        <label>
          <span>Password</span>
          <div className="password-field">
            <TextField
              fullWidth
              label="Password"
              type={showPassword ? 'text' : 'password'}
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              slotProps={{ input: { endAdornment: <InputAdornment position="end"><IconButton onClick={() => setShowPassword((prev) => !prev)} edge="end" aria-label="Toggle password visibility">{showPassword ? <VisibilityOff /> : <Visibility />}</IconButton></InputAdornment> } }}
            />
          </div>
        </label>

        {error && <div className="error-box">{error}</div>}

        <Button type="submit" variant="contained" fullWidth className="login-button" disabled={isLoading}>
          {isLoading ? 'LOGGING IN...' : 'LOG IN'}
        </Button>

        <Button type="button" variant="outlined" color="secondary" fullWidth startIcon={<Google />} onClick={handleGoogleLogin} disabled={isLoading}>
          Continue with Google
        </Button>

        <button type="button" className="text-link" onClick={() => navigate('/forgot-password')}>
          Forgot Password?
        </button>

        <div className="divider-row">
          <span>OR</span>
        </div>

        <Button type="button" variant="outlined" color="secondary" fullWidth onClick={() => navigate('/create-account')}>
          Create Account
        </Button>
      </form>
    </div>
  )
}

function OwnerLoginScreen() {
  const navigate = useNavigate()
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)

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
        <img className="brand-logo small" src={logoApp} alt="SJC Canteen" />
      </div>
      <div className="login-illustration gradient-amber"><span>Owner Access</span></div>
      <h1>Owner Login</h1>
      <p className="subtitle">Manage your canteen orders and inventory</p>
      <form className="login-form" onSubmit={async (event) => {
        event.preventDefault()
        setError('')
        setIsLoading(true)
        const form = new FormData(event.currentTarget)
        try {
          await loginWithRole(form.get('email'), form.get('password'), 'owner')
          navigate('/owner-home')
        } catch (loginError) {
          setError(loginError.message || 'Invalid owner credentials.')
        } finally {
          setIsLoading(false)
        }
      }}>
        <TextField name="email" type="email" label="Email" placeholder="owner@school.edu.ph" fullWidth />
        <TextField name="password" type="password" label="Password" placeholder="Enter your password" fullWidth />
        {error && <div className="error-box">{error}</div>}
        <Button type="submit" variant="contained" fullWidth className="login-button" disabled={isLoading}>{isLoading ? 'LOGGING IN...' : 'LOG IN'}</Button>
        <Button type="button" variant="outlined" color="secondary" fullWidth startIcon={<Google />} onClick={handleGoogleLogin} disabled={isLoading}>Continue with Google</Button>
      </form>
    </div>
  )
}

function ForgotPasswordScreen() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [error, setError] = useState('')

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/login')} aria-label="Go back"><ArrowBack /></IconButton>
      </div>
      <h1>Reset Password</h1>
      <p className="subtitle">Enter your email and we will send you a reset link.</p>
      <form className="login-form" onSubmit={async (event) => {
        event.preventDefault()
        setError('')
        try {
          await requestPasswordReset(email)
          setSent(true)
        } catch (resetError) {
          setError(resetError.message || 'Unable to send password reset email.')
        }
      }}>
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
  const [error, setError] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  return (
    <div className="screen-shell login-shell">
      <div className="login-header">
        <IconButton color="primary" onClick={() => navigate('/login')} aria-label="Go back"><ArrowBack /></IconButton>
      </div>
      <h1>Create Account</h1>
      <p className="subtitle">Register your student account to start ordering.</p>
      <form className="login-form" onSubmit={async (event) => {
        event.preventDefault()
        setError('')
        setIsLoading(true)
        const form = new FormData(event.currentTarget)
        try {
          await createStudentAccount({
            studentId: form.get('studentId'),
            name: form.get('name'),
            email: form.get('email'),
            password: form.get('password'),
          })
          navigate('/student-home')
        } catch (signupError) {
          setError(signupError.message || 'Unable to create the account.')
        } finally {
          setIsLoading(false)
        }
      }}>
        <TextField name="name" label="Full Name" placeholder="Your full name" fullWidth />
        <TextField name="studentId" label="Student ID" placeholder="06-2425-000000" fullWidth />
        <TextField name="email" type="email" label="Email" placeholder="you@example.com" fullWidth />
        <TextField name="password" type="password" label="Password" placeholder="Create a password" inputProps={{ minLength: 6 }} fullWidth />
        {error && <div className="error-box">{error}</div>}
        <Button type="submit" variant="contained" fullWidth disabled={isLoading}>{isLoading ? 'CREATING...' : 'CREATE ACCOUNT'}</Button>
      </form>
    </div>
  )
}

function StudentMenuScreen() {
  const [category, setCategory] = useState('All')
  const [cart, setCart] = useState([])
  const [cartOpen, setCartOpen] = useState(false)
  const [orderMessage, setOrderMessage] = useState('')
  const [isOrdering, setIsOrdering] = useState(false)
  const [paymentMethod, setPaymentMethod] = useState('Cash on Pickup')
  const [remoteFoods, setRemoteFoods] = useState([])
  const categories = ['All', 'Meals', 'Snacks', 'Drinks']
  const fallbackFoods = [
    { name: 'Chicken Rice Bowl', category: 'Meals', price: 85, image: foodOne },
    { name: 'Crispy Snack Box', category: 'Snacks', price: 55, image: foodTwo },
    { name: 'Fresh Fruit Drink', category: 'Drinks', price: 35, image: foodThree },
  ]
  useEffect(() => subscribeToFoodItems(setRemoteFoods, () => {}), [])
  const foods = remoteFoods.length > 0
    ? remoteFoods.filter((item) => item.isAvailable !== false).map((item) => ({
      id: item.id,
      name: item.title || item.name,
      category: item.category || 'Other',
      price: Number(item.price || 0),
      image: item.networkImage || foodOne,
    }))
    : fallbackFoods
  const visibleFoods = category === 'All' ? foods : foods.filter((food) => food.category === category)

  const addToCart = (food) => {
    setCart((items) => [...items, food])
    setOrderMessage('')
  }

  const handleCheckout = async () => {
    setIsOrdering(true)
    setOrderMessage('')
    try {
      const orderId = await placeStudentOrder(cart, paymentMethod)
      setCart([])
      setCartOpen(false)
      setOrderMessage(`Order #${orderId.slice(0, 5)} placed successfully.`)
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
          <h1>Hi, Student</h1>
        </div>
        <div className="avatar">S</div>
      </div>
      <div className="promo-panel">
        <span>Featured Today</span>
        <strong>Up to 20% OFF on healthy meals</strong>
        <small>Fuel your productive day.</small>
      </div>
      <div className="section-heading">
        <div><h2>Pick Food</h2><p>Healthy meals for a productive day</p></div>
        <Button className="cart-button" variant="contained" color="primary" onClick={() => setCartOpen((open) => !open)} aria-label="View cart">Cart ({cart.length})</Button>
      </div>
      {cartOpen && cart.length > 0 && (
        <div className="cart-panel">
          <strong>Your cart</strong>
          {cart.map((item, index) => <div className="cart-line" key={`${item.name}-${index}`}><span>{item.name}</span><span>PHP {item.price}</span></div>)}
          <div className="cart-total"><strong>Total</strong><strong>PHP {cart.reduce((sum, item) => sum + item.price, 0)}</strong></div>
          <div className="payment-methods">
            <strong>Payment method</strong>
            <Button className={paymentMethod === 'Cash on Pickup' ? 'payment-option selected' : 'payment-option'} variant={paymentMethod === 'Cash on Pickup' ? 'contained' : 'outlined'} onClick={() => setPaymentMethod('Cash on Pickup')}>Cash on Pickup</Button>
            <Button className={paymentMethod === 'GCash' ? 'payment-option selected' : 'payment-option'} variant={paymentMethod === 'GCash' ? 'contained' : 'outlined'} onClick={() => setPaymentMethod('GCash')}>GCash</Button>
          </div>
          <Button variant="contained" fullWidth onClick={handleCheckout} disabled={isOrdering}>{isOrdering ? 'PLACING ORDER...' : 'PLACE ORDER'}</Button>
        </div>
      )}
      {orderMessage && <div className="success-box order-message">{orderMessage}</div>}
      <div className="category-row">
        {categories.map((item) => (
          <Button key={item} className={category === item ? 'category active' : 'category'} variant={category === item ? 'contained' : 'outlined'} onClick={() => setCategory(item)}>
            {item}
          </Button>
        ))}
      </div>
      <div className="food-grid">
        {visibleFoods.map((food) => (
          <article className="food-card" key={food.name}>
            <img src={food.image} alt={food.name} />
            <div className="food-card-content">
              <span>{food.category}</span>
              <h3>{food.name}</h3>
              <div className="food-card-footer">
                <strong>PHP {food.price}</strong>
                <IconButton color="primary" className="add-button" onClick={() => addToCart(food)} aria-label={`Add ${food.name} to cart`}><AddShoppingCart /></IconButton>
              </div>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}

function OwnerDashboardScreen() {
  const navigate = useNavigate()
  const [orders, setOrders] = useState([])
  const [error, setError] = useState('')
  const [updatingOrder, setUpdatingOrder] = useState('')

  useEffect(() => {
    let unsubscribeAuth
    let unsubscribeOrders
    let active = true

    if (!auth) {
      setError('Firebase is not configured.')
      return undefined
    }

    unsubscribeAuth = onAuthStateChanged(auth, async (user) => {
      if (!user) {
        navigate('/owner-login', { replace: true })
        return
      }

      const profile = await getUserProfile(user.uid)
      if (!active) return
      if (profile?.role !== 'owner') {
        navigate('/owner-login', { replace: true })
        return
      }

      unsubscribeOrders = subscribeToAllOrders(setOrders, (orderError) => setError(orderError.message))
    })
    return () => {
      active = false
      unsubscribeAuth?.()
      unsubscribeOrders?.()
    }
  }, [navigate])

  const acceptOrder = async (orderId) => {
    setUpdatingOrder(orderId)
    try {
      await updateOrderStatus(orderId, 'Accepted')
      setOrders((items) => items.map((item) => item.id === orderId ? { ...item, status: 'Accepted' } : item))
    } catch (orderError) {
      setError(orderError.message)
    } finally {
      setUpdatingOrder('')
    }
  }

  return (
    <div className="screen-shell">
      <div className="welcome-panel">
        <span className="eyebrow">SJC CANTEEN</span>
        <h1>Owner Dashboard</h1>
        <p>Manage today&apos;s menu, inventory, and student orders.</p>
      </div>
      {error && <div className="error-box">{error}</div>}
      <div className="owner-order-list">
        <div className="section-heading"><h2>Incoming Orders</h2><span>{orders.length} total</span></div>
        {orders.length === 0 && <div className="empty-panel">No orders yet.</div>}
        {orders.map((order) => (
          <article className="owner-order" key={order.id}>
            <div className="order-heading"><strong>{order.studentName || 'Student'}</strong><span className={`status status-${String(order.status).toLowerCase()}`}>{order.status}</span></div>
            <p>{order.itemsDescription}</p>
            <div className="order-heading"><strong>PHP {order.total}</strong><span>{order.paymentMethod || 'Payment not recorded'}</span></div>
            {order.status === 'Pending' && <button className="primary-button" onClick={() => acceptOrder(order.id)} disabled={updatingOrder === order.id}>{updatingOrder === order.id ? 'ACCEPTING...' : 'ACCEPT ORDER'}</button>}
          </article>
        ))}
      </div>
    </div>
  )
}

function StudentNavigationScreen() {
  const [tab, setTab] = useState('Menu')
  const views = {
    Menu: <StudentMenuScreen />,
    Orders: <StudentOrdersScreen history={false} />,
    History: <StudentOrdersScreen history />,
    Profile: <StudentProfileScreen />,
  }

  return (
    <div className="app-shell">
      {views[tab]}
      <nav className="bottom-nav student-nav">
        {['Menu', 'Orders', 'History', 'Profile'].map((item) => <Button key={item} className={tab === item ? 'nav-item active' : 'nav-item'} variant="text" onClick={() => setTab(item)}>{item}</Button>)}
      </nav>
    </div>
  )
}

function StudentOrdersScreen({ history }) {
  const [orders, setOrders] = useState([])
  const [error, setError] = useState('')

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

  const activeStatuses = ['Pending', 'Accepted', 'Preparing', 'Ready for Pickup']
  const visibleOrders = orders.filter((order) => history ? !activeStatuses.includes(order.status) : activeStatuses.includes(order.status))

  return (
    <div className="screen-shell dashboard-screen">
      <div className="page-heading"><span className="eyebrow">SJC CANTEEN</span><h1>{history ? 'Order History' : 'Active Orders'}</h1><p>{history ? 'Your previous canteen orders.' : 'Track your meals from order to pickup.'}</p></div>
      {error && <div className="error-box">{error}</div>}
      <div className="order-list">
        {visibleOrders.length === 0 && <div className="empty-panel">No {history ? 'past' : 'active'} orders yet.</div>}
        {visibleOrders.map((order) => <article className="student-order" key={order.id}><div className="order-heading"><strong>{order.itemsDescription || 'Order items'}</strong><span className="status">{order.status}</span></div><p>PHP {order.total} · {order.paymentMethod || 'Payment not recorded'}</p><small>{order.studentId || ''}</small></article>)}
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
    return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">ACCOUNT</span><h1>Student Profile</h1><p>Loading your account...</p></div></div>
  }

  return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">ACCOUNT</span><h1>Student Profile</h1><p>Manage your account details and preferences.</p></div><div className="profile-card"><div className="avatar large">{(name || 'S').charAt(0).toUpperCase()}</div><label><span>Full Name</span><input value={name} onChange={(event) => setName(event.target.value)} /></label><label><span>Email</span><input value={profile?.email || auth?.currentUser?.email || ''} disabled /></label><label><span>Student ID</span><input value={profile?.studentId || ''} disabled /></label><button className="secondary-button" onClick={() => navigate('/notifications')}>NOTIFICATIONS</button><button className="primary-button" onClick={saveProfile}>SAVE PROFILE</button>{message && <div className="success-box">{message}</div>}<button className="secondary-button" onClick={logoutStudent}>LOG OUT</button></div></div>
}

function NotificationsScreen() {
  const [notifications, setNotifications] = useState([])
  useEffect(() => {
    if (!auth) return undefined
    let unsubscribeNotifications
    const unsubscribeAuth = onAuthStateChanged(auth, (user) => {
      if (user) unsubscribeNotifications = subscribeToNotifications(user.uid, setNotifications, () => {})
    })
    return () => { unsubscribeAuth(); unsubscribeNotifications?.() }
  }, [])
  return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">UPDATES</span><h1>Notifications</h1><p>Order updates and canteen announcements.</p></div><div className="order-list">{notifications.length === 0 && <div className="empty-panel">No notifications yet.</div>}{notifications.map((notification) => <article className="student-order" key={notification.id} onClick={() => markNotificationRead(notification.id)}><div className="order-heading"><strong>{notification.title}</strong><span className="status">{notification.isRead ? 'Read' : 'New'}</span></div><p>{notification.message}</p></article>)}</div></div>
}

function OwnerNavigationScreen() {
  const [tab, setTab] = useState('Dashboard')
  const views = { Dashboard: <OwnerDashboardScreen />, Orders: <OwnerOrdersScreen />, Analytics: <OwnerAnalyticsScreen />, Inventory: <OwnerInventoryScreen />, Profile: <OwnerProfileScreen /> }
  return (
    <div className="app-shell">
      {views[tab]}
      <nav className="bottom-nav owner-nav">
        {['Dashboard', 'Orders', 'Analytics', 'Inventory', 'Profile'].map((item) => (
          <Button key={item} className={tab === item ? 'nav-item active' : 'nav-item'} variant="text" onClick={() => setTab(item)}>
            {item}
          </Button>
        ))}
      </nav>
    </div>
  )
}

function OwnerOrdersScreen() {
  const [orders, setOrders] = useState([])
  const [error, setError] = useState('')
  useEffect(() => { const unsubscribe = subscribeToAllOrders(setOrders, (orderError) => setError(orderError.message)); return unsubscribe }, [])
  const advance = async (order) => { const next = order.status === 'Pending' ? 'Accepted' : order.status === 'Accepted' ? 'Preparing' : order.status === 'Preparing' ? 'Ready for Pickup' : 'Completed'; await updateOrderStatus(order.id, next) }
  return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">OPERATIONS</span><h1>Orders</h1><p>Review and advance student orders.</p></div>{error && <div className="error-box">{error}</div>}<div className="order-list">{orders.length === 0 && <div className="empty-panel">No orders yet.</div>}{orders.map((order) => <article className="owner-order" key={order.id}><div className="order-heading"><strong>{order.studentName || 'Student'}</strong><span className="status">{order.status}</span></div><p>{order.itemsDescription}</p><div className="order-heading"><strong>PHP {order.total}</strong><span>{order.paymentMethod || 'Payment not recorded'}</span></div>{order.status !== 'Completed' && <button className="primary-button" onClick={() => advance(order)}>MARK {order.status === 'Pending' ? 'ACCEPTED' : order.status === 'Accepted' ? 'PREPARING' : order.status === 'Preparing' ? 'READY' : 'COMPLETED'}</button>}</article>)}</div></div>
}

function OwnerAnalyticsScreen() {
  const [orders, setOrders] = useState([])
  useEffect(() => subscribeToAllOrders(setOrders, () => {}), [])
  const revenue = orders.reduce((sum, order) => sum + Number(order.total || 0), 0)
  const completed = orders.filter((order) => order.status === 'Completed').length
  return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">OPERATIONS</span><h1>Analytics</h1><p>Snapshot of canteen performance.</p></div><div className="metric-grid"><div className="metric-card"><span>Total Revenue</span><strong>PHP {revenue}</strong></div><div className="metric-card"><span>Total Orders</span><strong>{orders.length}</strong></div><div className="metric-card"><span>Completed</span><strong>{completed}</strong></div><div className="metric-card"><span>Customers</span><strong>{new Set(orders.map((order) => order.studentUiD)).size}</strong></div></div></div>
}

function OwnerInventoryScreen() {
  const [items, setItems] = useState([])
  const [form, setForm] = useState({ title: '', price: '', category: 'Meals' })
  const [message, setMessage] = useState('')
  useEffect(() => subscribeToFoodItems(setItems, () => {}), [])
  const addItem = async (event) => { event.preventDefault(); await addFoodItem(form); setForm({ title: '', price: '', category: 'Meals' }); setMessage('Menu item added.') }
  return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">CATALOG</span><h1>Inventory</h1><p>Add menu items and control availability.</p></div><form className="inventory-form" onSubmit={addItem}><input placeholder="Item name" value={form.title} onChange={(event) => setForm({ ...form, title: event.target.value })} required /><input type="number" min="0" placeholder="Price" value={form.price} onChange={(event) => setForm({ ...form, price: event.target.value })} required /><select value={form.category} onChange={(event) => setForm({ ...form, category: event.target.value })}><option>Meals</option><option>Snacks</option><option>Drinks</option></select><button className="primary-button">ADD ITEM</button></form>{message && <div className="success-box">{message}</div>}<div className="order-list">{items.map((item) => <article className="owner-order" key={item.id}><div className="order-heading"><strong>{item.title}</strong><span>PHP {item.price}</span></div><p>{item.category} · {item.isAvailable === false ? 'Unavailable' : 'Available'}</p><button className="secondary-button" onClick={() => toggleFoodAvailability(item.id, item.isAvailable !== false)}>{item.isAvailable === false ? 'MAKE AVAILABLE' : 'MARK SOLD OUT'}</button><button className="text-link" onClick={() => deleteFoodItem(item.id)}>DELETE ITEM</button></article>)}</div></div>
}

function OwnerProfileScreen() {
  const navigate = useNavigate()
  const [profile, setProfile] = useState(null)
  useEffect(() => { if (auth?.currentUser) getUserProfile(auth.currentUser.uid).then(setProfile) }, [])
  const logoutOwner = async () => { await logoutUser(); navigate('/owner-login', { replace: true }) }
  return <div className="screen-shell dashboard-screen"><div className="page-heading"><span className="eyebrow">ACCOUNT</span><h1>Store Profile</h1><p>Manage your SJC Canteen owner account.</p></div><div className="profile-card"><div className="avatar large">{(profile?.name || 'O').charAt(0).toUpperCase()}</div><h2>{profile?.name || 'Canteen owner'}</h2><p>{profile?.email || ''}</p><p>{profile?.storeName || 'SJC Canteen'}</p><button className="secondary-button" onClick={logoutOwner}>LOG OUT</button></div></div>
}

export default App
