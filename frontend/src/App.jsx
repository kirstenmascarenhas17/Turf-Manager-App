import { useState, useEffect } from 'react'

// Premium Athletic Color Palette
const colors = {
  bodyBg: "#0B0B0B",       // Deep, premium black background
  cardBg: "#161616",       // Dark grey card containers for depth
  border: "#262626",       // Subtle dark border lines
  accentRed: "#B4121B",    // High-performance Crimson Red
  textPrimary: "#FFFFFF",  // Crisp white for readability
  textSecondary: "#A3A3A3",// Muted grey for sub-labels
  inputBg: "#222222",      // Solid dark input background
}

function App() {
  const [squads, setSquads] = useState([])
  const [loading, setLoading] = useState(true)
  const [matchForm, setMatchForm] = useState({
    title: '',
    date_time: '',
    turf_details: '',
    total_cost: '',
    max_slots: 10,
    squad_id: ''
  })

  useEffect(() => {
    fetch('http://127.0.0.1:8000/squads/')
      .then(response => response.json())
      .then(data => {
        setSquads(data)
        setLoading(false)
        if (data.length > 0) {
          setMatchForm(prev => ({ ...prev, squad_id: data[0].id }))
        }
      })
      .catch(error => {
        console.error("Error fetching squads:", error)
        setLoading(false)
      })
  }, [])

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setMatchForm(prev => ({ ...prev, [name]: value }));
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch('http://127.0.0.1:8000/matches/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...matchForm,
          total_cost: parseFloat(matchForm.total_cost) || 0,
          max_slots: parseInt(matchForm.max_slots) || 10,
          squad_id: parseInt(matchForm.squad_id)
        })
      });

      if (response.ok) {
        alert("Match successfully scheduled!");
        setMatchForm(prev => ({ ...prev, title: '', date_time: '', turf_details: '', total_cost: '' }));
      } else {
        const err = await response.json();
        alert("Error creating match: " + JSON.stringify(err));
      }
    } catch (error) {
      console.error("Submission failed", error);
    }
  }

  return (
    <div style={{ 
      backgroundColor: colors.bodyBg, 
      minHeight: '100vh', 
      width: '100%',
      color: colors.textPrimary, 
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      margin: 0,
      padding: 0,
      boxSizing: 'border-box'
    }}>
      
      {/* Inject Global Style Overrides */}
      <style>{`
        html, body, #root {
          margin: 0 !important;
          padding: 0 !important;
          width: 100% !important;
          max-width: 100% !important;
          background-color: ${colors.bodyBg};
          overflow-x: hidden;
        }
        * {
          box-sizing: border-box;
        }
        input, select {
          color: ${colors.textPrimary} !important;
          background-color: ${colors.inputBg} !important;
        }
        input::placeholder {
          color: #555555 !important;
        }
      `}</style>

      {/* Top Professional Banner Navigation */}
      <nav style={{ 
        backgroundColor: '#000000', 
        borderBottom: `2px solid ${colors.accentRed}`, 
        padding: '1rem 2rem',
        display: 'flex',
        alignItems: 'center',
        gap: '1rem'
      }}>
        
        {/* GEOMETRIC FOOLPROOF LOGO */}
        <svg width="42" height="42" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="gradTop" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="#FF2A35" />
              <stop offset="100%" stopColor="#7A0C12" />
            </linearGradient>
            <linearGradient id="gradStem" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#B4121B" />
              <stop offset="100%" stopColor="#4A050A" />
            </linearGradient>
            <filter id="dropShadow" x="-20%" y="-20%" width="140%" height="140%">
              <feDropShadow dx="0" dy="6" stdDeviation="4" floodColor="#000000" floodOpacity="0.6"/>
            </filter>
          </defs>

          {/* Stem (Perfectly centered at x=50) */}
          <rect x="38" y="30" width="24" height="60" rx="12" fill="url(#gradStem)" />
          
          {/* Top Bar with Shadow overlapping the stem */}
          <rect x="10" y="15" width="80" height="28" rx="14" fill="url(#gradTop)" filter="url(#dropShadow)" />
        </svg>

        <span style={{ fontSize: '1.3rem', fontWeight: '900', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
          TURF MANAGER <span style={{ color: colors.accentRed }}>// DASHBOARD</span>
        </span>
      </nav>
      
      {/* Real Full-Width Layout Wrapper */}
      <div style={{ 
        width: '100%',
        padding: '2rem', 
        display: 'flex',
        flexDirection: 'column',
        gap: '2rem' 
      }}>
        
        {/* Responsive Dashboard Grid */}
        <main style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))',
          gap: '2rem',
          width: '100%'
        }}>
          
          {/* Left Panel: Squads Overview */}
          <div style={{ 
            backgroundColor: colors.cardBg, 
            padding: '2rem', 
            borderRadius: '4px', 
            borderLeft: `4px solid ${colors.accentRed}`,
            boxShadow: '0 4px 12px rgba(0,0,0,0.5)',
            alignSelf: 'start'
          }}>
            <h2 style={{ fontSize: '1.4rem', fontWeight: '800', marginTop: 0, marginBottom: '1.5rem', letterSpacing: '0.03em' }}>
              YOUR SQUADS
            </h2>
            
            {loading ? (
              <p style={{ color: colors.textSecondary }}>Accessing secure database...</p>
            ) : squads.length === 0 ? (
              <p style={{ color: colors.textSecondary }}>No active squads registered.</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {squads.map(squad => (
                  <div key={squad.id} style={{ 
                      backgroundColor: '#1C1C1C', 
                      padding: '1.25rem', 
                      borderRadius: '4px', 
                      border: `1px solid ${colors.border}`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between'
                    }}>
                    <span style={{ fontWeight: '700', fontSize: '1.1rem' }}>{squad.name.toUpperCase()}</span>
                    <span>
                      <code style={{ 
                        backgroundColor: colors.accentRed, 
                        color: '#FFFFFF', 
                        padding: '4px 8px', 
                        borderRadius: '2px',
                        fontSize: '0.85rem',
                        fontWeight: '700',
                        letterSpacing: '0.05em'
                      }}>
                        {squad.invite_code}
                      </code>
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Right Panel: Organize Match Form */}
          <div style={{ 
            backgroundColor: colors.cardBg, 
            padding: '2rem', 
            borderRadius: '4px', 
            borderTop: `4px solid ${colors.accentRed}`,
            boxShadow: '0 4px 12px rgba(0,0,0,0.5)'
          }}>
            <h2 style={{ fontSize: '1.4rem', fontWeight: '800', marginTop: 0, marginBottom: '1.5rem', letterSpacing: '0.03em' }}>
              ORGANIZE A MATCH
            </h2>

            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>SELECT SQUAD</label>
                <select 
                  name="squad_id" 
                  value={matchForm.squad_id} 
                  onChange={handleInputChange}
                  style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }}
                  required
                >
                  <option value="">-- CHOOSE SQUAD --</option>
                  {squads.map(s => <option key={s.id} value={s.id}>{s.name.toUpperCase()}</option>)}
                </select>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>MATCH TITLE</label>
                <input type="text" name="title" placeholder="e.g. FRIDAY NIGHT 5V5" value={matchForm.title} onChange={handleInputChange} style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }} required />
              </div>

              <div style={{ display: 'flex', gap: '1.5rem' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', flex: 1 }}>
                  <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>DATE & TIME</label>
                  <input type="datetime-local" name="date_time" value={matchForm.date_time} onChange={handleInputChange} style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }} required />
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', width: '120px' }}>
                  <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>MAX SLOTS</label>
                  <input type="number" name="max_slots" value={matchForm.max_slots} onChange={handleInputChange} style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }} min="2" max="22" required />
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>TURF DETAILS</label>
                <input type="text" name="turf_details" placeholder="e.g. ANDHERI SPORTS COMPLEX" value={matchForm.turf_details} onChange={handleInputChange} style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }} />
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>TOTAL TURF COST (₹)</label>
                <input type="number" name="total_cost" placeholder="1500" value={matchForm.total_cost} onChange={handleInputChange} style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }} min="0" step="0.01" />
              </div>

              <button type="submit" style={{ 
                marginTop: '1rem',
                backgroundColor: colors.accentRed, 
                color: '#FFFFFF', 
                padding: '1rem', 
                borderRadius: '4px', 
                border: 'none',
                fontSize: '1rem',
                fontWeight: '900',
                letterSpacing: '0.05em',
                cursor: 'pointer',
                transition: 'transform 0.1s, background-color 0.2s',
              }}
              onMouseEnter={(e) => e.target.style.backgroundColor = '#940F14'}
              onMouseLeave={(e) => e.target.style.backgroundColor = colors.accentRed}
              >
                SCHEDULE MATCH
              </button>

            </form>
          </div>
          
        </main>
      </div>
    </div>
  )
}

export default App