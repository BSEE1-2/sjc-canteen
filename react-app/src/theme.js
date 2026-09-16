import { createTheme } from '@mui/material/styles'

export const appTheme = createTheme({
  palette: {
    primary: {
      main: '#63A002',
      dark: '#356000',
      light: '#B0D77E',
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: '#596248',
      light: '#DDE8C8',
      contrastText: '#FFFFFF',
    },
    info: {
      main: '#416278',
      contrastText: '#FFFFFF',
    },
    error: {
      main: '#BA1A1A',
      contrastText: '#FFFFFF',
    },
    background: {
      default: '#F9FBEF',
      paper: '#FFFFFF',
    },
    text: {
      primary: '#1A1C16',
      secondary: '#46483D',
    },
    divider: '#C7CBB8',
  },
  typography: {
    fontFamily: '"Plus Jakarta Sans", "Noto Sans", sans-serif',
    h1: { fontWeight: 800 },
    h2: { fontWeight: 800 },
    h3: { fontWeight: 800 },
    button: { fontWeight: 800, textTransform: 'none' },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: { borderRadius: 16, minHeight: 56, paddingInline: 18, transition: 'transform 180ms ease, box-shadow 180ms ease' },
        contained: { '&:hover': { transform: 'translateY(-2px)', boxShadow: '0 8px 18px rgba(82, 103, 101, 0.24)' } },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: { border: '1px solid #D9E5E2', boxShadow: '0 10px 24px rgba(23, 32, 31, 0.06)' },
      },
    },
    MuiTextField: {
      defaultProps: { size: 'medium' },
    },
    MuiChip: {
      styleOverrides: {
        root: { fontWeight: 800 },
      },
    },
  },
})
