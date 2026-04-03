/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#0f1117',
        card: '#1c1f2e',
        'card-hover': '#222638',
        panel: '#13161f',
        border: '#252a38',
        'border-hover': '#353d54',
        muted: '#7a8299',
        faint: '#4a5068',
        accent: '#3b82f6',
        score: {
          5: '#22c55e',
          4: '#84cc16',
          3: '#f59e0b',
          2: '#f97316',
          1: '#ef4444',
        },
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'SF Pro Display', 'Segoe UI', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        ios: '13px',
        'ios-sm': '9px',
        'ios-lg': '20px',
      },
    },
  },
  plugins: [],
}
