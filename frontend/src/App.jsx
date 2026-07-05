import { useState, useEffect, useRef } from 'react'

// Premium Athletic Color Palette
const colors = {
  bodyBg: "#0B0B0B",       
  cardBg: "#161616",       
  border: "#262626",       
  accentRed: "#B4121B",    
  textPrimary: "#FFFFFF",  
  textSecondary: "#A3A3A3",
  inputBg: "#222222",      
}

function App() {
  const [squads, setSquads] = useState([])
  const [matches, setMatches] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedLedger, setSelectedLedger] = useState(null)
  
  // --- AI CHAT STATE ---
  const [aiQuery, setAiQuery] = useState('')
  const [chatHistory, setChatHistory] = useState([]) // Now an array to keep history!
  const [aiLoading, setAiLoading] = useState(false)
  const [isChatOpen, setIsChatOpen] = useState(false)
  
  const chatEndRef = useRef(null) // Used for auto-scrolling

  const [matchForm, setMatchForm] = useState({
    title: '',
    date_time: '',
    turf_details: '',
    total_cost: '',
    max_slots: 10,
    squad_id: ''
  })

  // Auto-scroll to the bottom of the chat when messages update
  useEffect(() => {
    if (chatEndRef.current) {
      chatEndRef.current.scrollIntoView({ behavior: 'smooth' })
    }
  }, [chatHistory, aiLoading])

  const fetchData = () => {
    fetch('http://127.0.0.1:8000/squads/')
      .then(res => res.json())
      .then(data => {
        setSquads(data)
        if (data.length > 0 && !matchForm.squad_id) {
          setMatchForm(prev => ({ ...prev, squad_id: data[0].id }))
        }
      })
      .catch(err => console.error("Squad fetch error", err))

    fetch('http://127.0.0.1:8000/matches/')
      .then(res => res.json())
      .then(data => {
        setMatches(data)
        setLoading(false)
      })
      .catch(err => {
        console.error("Match fetch error", err)
        setLoading(false)
      })
  }

  useEffect(() => {
    fetchData()
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
        fetchData(); 
      } else {
        const err = await response.json();
        alert("Error creating match: " + JSON.stringify(err));
      }
    } catch (error) {
      console.error("Submission failed", error);
    }
  }

  const handleViewLedger = async (matchId) => {
    try {
      const response = await fetch(`http://127.0.0.1:8000/matches/${matchId}/ledger`);
      if (response.ok) {
        const data = await response.json();
        setSelectedLedger(data);
      } else {
        alert("Could not load ledger data.");
      }
    } catch (error) {
      console.error("Ledger fetch failed", error);
    }
  }

  const handleUPIPayment = (amount, title) => {
    const captainUpi = "turfmanager@ybl";
    const upiUrl = `upi://pay?pa=${captainUpi}&pn=Turf%20Captain&am=${amount}&cu=INR&tn=Turf%20Split:%20${encodeURIComponent(title)}`;
    window.location.href = upiUrl;
  }

  // --- UPDATED MESSAGE STREAM LOGIC ---
  const handleAIQuery = async (e) => {
    e.preventDefault();
    if (!aiQuery.trim()) return;
    
    const userMessage = aiQuery;
    
    // Add user message to UI instantly
    setChatHistory(prev => [...prev, { role: 'user', content: userMessage }]);
    setAiQuery(''); // Clear the input box
    setAiLoading(true);
    
    try {
      const res = await fetch('http://127.0.0.1:8000/ai/ask', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query: userMessage })
      });
      
      const data = await res.json();
      
      // Add AI response to UI
      if (data.error) {
        setChatHistory(prev => [...prev, { role: 'ai', content: "AI Error: " + data.message }]);
      } else {
        setChatHistory(prev => [...prev, { role: 'ai', content: data.ai_answer }]);
      }
    } catch (error) {
      setChatHistory(prev => [...prev, { role: 'ai', content: "System Error: Could not reach the AI core." }]);
    }
    setAiLoading(false);
  }

  return (
    <div style={{ backgroundColor: colors.bodyBg, minHeight: '100vh', width: '100%', color: colors.textPrimary, fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', margin: 0, padding: 0, boxSizing: 'border-box' }}>
      
      <style>{`
        html, body, #root { margin: 0 !important; padding: 0 !important; width: 100% !important; max-width: 100% !important; background-color: ${colors.bodyBg}; overflow-x: hidden; }
        * { box-sizing: border-box; }
        input, select { color: ${colors.textPrimary} !important; background-color: ${colors.inputBg} !important; }
        input::placeholder { color: #555555 !important; }
        
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #333; border-radius: 4px; }
        ::-webkit-scrollbar-thumb:hover { background: #555; }
      `}</style>

      {/* FIXED HEADER */}
      <nav style={{ 
        backgroundColor: '#000000', borderBottom: `2px solid ${colors.accentRed}`, padding: '0.75rem 2rem', 
        display: 'flex', alignItems: 'center', justifyContent: 'space-between', 
        position: 'fixed', top: 0, left: 0, right: 0, width: '100%', zIndex: 2000, 
        boxShadow: '0 4px 12px rgba(0,0,0,0.7)', boxSizing: 'border-box'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
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
            </defs>
            <rect x="38" y="30" width="24" height="60" rx="12" fill="url(#gradStem)" />
            <rect x="10" y="15" width="80" height="28" rx="14" fill="url(#gradTop)" />
          </svg>
          <span style={{ fontSize: '1.3rem', fontWeight: '900', letterSpacing: '0.05em', textTransform: 'uppercase' }}>
            TURF MANAGER <span style={{ color: colors.accentRed }}>// DASHBOARD</span>
          </span>
        </div>

        <div style={{ position: 'relative' }}> 
          <button 
            onClick={() => setIsChatOpen(!isChatOpen)}
            style={{
              backgroundColor: 'transparent',
              color: isChatOpen ? colors.accentRed : colors.textPrimary,
              border: `1px solid ${isChatOpen ? colors.accentRed : colors.border}`,
              borderRadius: '4px',
              padding: '0.6rem 1.2rem',
              display: 'flex',
              alignItems: 'center',
              cursor: 'pointer',
              fontWeight: '800',
              fontSize: '0.95rem',
              letterSpacing: '0.05em',
              transition: 'all 0.2s',
              zIndex: 2001
            }}
          >
            AI CHATBOT
          </button>

          {isChatOpen && (
            <div style={{
              position: 'absolute', top: '120%', right: 0, width: '380px', height: '520px', 
              backgroundColor: colors.cardBg, borderRadius: '8px', border: `1px solid ${colors.border}`,
              borderTop: `4px solid ${colors.accentRed}`, boxShadow: '-8px 8px 32px rgba(0,0,0,0.9)',
              display: 'flex', flexDirection: 'column', zIndex: 2000, overflow: 'hidden'
            }}>
              
              <div style={{ padding: '1rem', borderBottom: `1px solid ${colors.border}`, backgroundColor: '#111', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h3 style={{ margin: 0, fontSize: '1rem', fontWeight: '800', letterSpacing: '0.05em', color: colors.accentRed }}>AI CHATBOT</h3>
                <button onClick={() => setIsChatOpen(false)} style={{ background: 'none', border: 'none', color: colors.textSecondary, cursor: 'pointer', fontSize: '1.2rem' }}>✕</button>
              </div>

              {/* MESSAGE STREAM UI */}
              <div style={{ flex: 1, padding: '1rem', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {chatHistory.length === 0 ? (
                  <p style={{ color: colors.textSecondary, fontSize: '0.9rem', textAlign: 'center', margin: 'auto' }}>
                    Ask me anything about your squads, matches, or ledger balances.
                  </p>
                ) : (
                  chatHistory.map((msg, idx) => (
                    <div key={idx} style={{
                      alignSelf: msg.role === 'user' ? 'flex-end' : 'flex-start',
                      backgroundColor: msg.role === 'user' ? colors.accentRed : '#1C1C1C',
                      color: colors.textPrimary,
                      padding: '0.75rem 1rem',
                      borderRadius: '8px',
                      borderBottomRightRadius: msg.role === 'user' ? '0' : '8px',
                      borderBottomLeftRadius: msg.role === 'ai' ? '0' : '8px',
                      maxWidth: '85%',
                      fontSize: '0.9rem',
                      lineHeight: '1.4',
                      border: msg.role === 'ai' ? `1px solid ${colors.border}` : 'none'
                    }}>
                      {/* Using dangerouslySetInnerHTML to parse any bold asterisks if needed, but keeping it simple for now */}
                      {msg.content}
                    </div>
                  ))
                )}
                
                {aiLoading && (
                  <div style={{ alignSelf: 'flex-start', backgroundColor: '#1C1C1C', color: colors.textSecondary, padding: '0.75rem 1rem', borderRadius: '8px', borderBottomLeftRadius: '0', fontSize: '0.9rem', border: `1px solid ${colors.border}` }}>
                    Thinking...
                  </div>
                )}
                {/* Invisible element to anchor the auto-scroll */}
                <div ref={chatEndRef} />
              </div>

              <form onSubmit={handleAIQuery} style={{ padding: '1rem', borderTop: `1px solid ${colors.border}`, backgroundColor: '#111', display: 'flex', gap: '0.5rem' }}>
                <input 
                  type="text" 
                  placeholder="Type a message..." 
                  value={aiQuery} 
                  onChange={(e) => setAiQuery(e.target.value)} 
                  style={{ flex: 1, padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '0.9rem', outline: 'none', width: '100%' }} 
                  required 
                />
                <button 
                  type="submit" 
                  disabled={aiLoading} 
                  style={{ backgroundColor: aiLoading ? '#555' : colors.accentRed, color: '#FFFFFF', padding: '0 1.25rem', borderRadius: '4px', border: 'none', fontWeight: '900', cursor: aiLoading ? 'not-allowed' : 'pointer', letterSpacing: '0.05em' }}
                >
                  ASK
                </button>
              </form>

            </div>
          )}
        </div>
      </nav>
      
      <div style={{ width: '100%', padding: '2rem', paddingTop: '6.5rem', display: 'flex', flexDirection: 'column', gap: '2rem' }}>
        <main style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '2rem', width: '100%' }}>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <div style={{ backgroundColor: colors.cardBg, padding: '2rem', borderRadius: '4px', borderLeft: `4px solid ${colors.accentRed}`, boxShadow: '0 4px 12px rgba(0,0,0,0.5)' }}>
              <h2 style={{ fontSize: '1.4rem', fontWeight: '800', marginTop: 0, marginBottom: '1.5rem', letterSpacing: '0.03em' }}>YOUR SQUADS</h2>
              {loading ? <p style={{ color: colors.textSecondary }}>Accessing secure database...</p> : squads.length === 0 ? <p style={{ color: colors.textSecondary }}>No active squads registered.</p> : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {squads.map(squad => (
                    <div key={squad.id} style={{ backgroundColor: '#1C1C1C', padding: '1.25rem', borderRadius: '4px', border: `1px solid ${colors.border}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                      <span style={{ fontWeight: '700', fontSize: '1.1rem' }}>{squad.name.toUpperCase()}</span>
                      <code style={{ backgroundColor: colors.accentRed, color: '#FFFFFF', padding: '4px 8px', borderRadius: '2px', fontSize: '0.85rem', fontWeight: '700', letterSpacing: '0.05em' }}>{squad.invite_code}</code>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div style={{ backgroundColor: colors.cardBg, padding: '2rem', borderRadius: '4px', borderLeft: `4px solid ${colors.accentRed}`, boxShadow: '0 4px 12px rgba(0,0,0,0.5)' }}>
              <h2 style={{ fontSize: '1.4rem', fontWeight: '800', marginTop: 0, marginBottom: '1.5rem', letterSpacing: '0.03em' }}>UPCOMING MATCHES</h2>
              {matches.length === 0 ? <p style={{ color: colors.textSecondary }}>No matches scheduled yet.</p> : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {Array.isArray(matches) && matches.map((match) => (
                    <div key={match.id} style={{ backgroundColor: '#1C1C1C', padding: '1rem', borderRadius: '4px', border: `1px solid ${colors.border}`, display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontWeight: '700', fontSize: '1.1rem' }}>{match.title.toUpperCase()}</span>
                        <span style={{ color: colors.accentRed, fontWeight: '800' }}>₹{match.total_cost}</span>
                      </div>
                      <span style={{ fontSize: '0.85rem', color: colors.textSecondary }}>
                        {new Date(match.date_time).toLocaleString()} • {match.max_slots} Slots
                      </span>
                      <button 
                        onClick={() => handleViewLedger(match.id)}
                        style={{ marginTop: '0.5rem', backgroundColor: 'transparent', color: colors.textPrimary, border: `1px solid ${colors.accentRed}`, padding: '0.5rem', borderRadius: '2px', cursor: 'pointer', fontWeight: '700', letterSpacing: '0.05em' }}
                      >
                        VIEW FINANCIAL LEDGER
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
            <div style={{ backgroundColor: colors.cardBg, padding: '2rem', borderRadius: '4px', borderTop: `4px solid ${colors.accentRed}`, boxShadow: '0 4px 12px rgba(0,0,0,0.5)' }}>
              <h2 style={{ fontSize: '1.4rem', fontWeight: '800', marginTop: 0, marginBottom: '1.5rem', letterSpacing: '0.03em' }}>ORGANIZE A MATCH</h2>
              <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                  <label style={{ fontSize: '0.85rem', fontWeight: '700', color: colors.textSecondary, letterSpacing: '0.05em' }}>SELECT SQUAD</label>
                  <select name="squad_id" value={matchForm.squad_id} onChange={handleInputChange} style={{ padding: '0.75rem', borderRadius: '4px', border: `1px solid ${colors.border}`, fontSize: '1rem', outline: 'none' }} required>
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
                <button type="submit" style={{ marginTop: '1rem', backgroundColor: colors.accentRed, color: '#FFFFFF', padding: '1rem', borderRadius: '4px', border: 'none', fontSize: '1rem', fontWeight: '900', letterSpacing: '0.05em', cursor: 'pointer' }}>SCHEDULE MATCH</button>
              </form>
            </div>

            {selectedLedger && (
              <div style={{ backgroundColor: colors.cardBg, padding: '2rem', borderRadius: '4px', borderTop: `4px solid ${colors.accentRed}`, boxShadow: '0 4px 12px rgba(0,0,0,0.5)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
                  <h2 style={{ fontSize: '1.4rem', fontWeight: '800', marginTop: 0, margin: 0, letterSpacing: '0.03em', color: colors.accentRed }}>FINANCIAL LEDGER</h2>
                  <button onClick={() => setSelectedLedger(null)} style={{ background: 'none', border: 'none', color: colors.textSecondary, cursor: 'pointer', fontSize: '1.2rem' }}>✕</button>
                </div>
                
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: `1px solid ${colors.border}`, paddingBottom: '0.5rem' }}>
                    <span style={{ color: colors.textSecondary, fontWeight: '700' }}>MATCH</span>
                    <span style={{ fontWeight: '700' }}>{selectedLedger.title.toUpperCase()}</span>
                  </div>
                  
                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: `1px solid ${colors.border}`, paddingBottom: '0.5rem' }}>
                    <span style={{ color: colors.textSecondary, fontWeight: '700' }}>TOTAL COST</span>
                    <span style={{ fontWeight: '700' }}>₹{selectedLedger.total_cost}</span>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: `1px solid ${colors.border}`, paddingBottom: '0.5rem' }}>
                    <span style={{ color: colors.textSecondary, fontWeight: '700' }}>ACTIVE PLAYERS</span>
                    <span style={{ fontWeight: '700' }}>{selectedLedger.active_players} RSVP'd</span>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', paddingBottom: '0.5rem', marginTop: '0.5rem' }}>
                    <span style={{ color: colors.accentRed, fontWeight: '800', fontSize: '1.1rem' }}>YOUR SPLIT</span>
                    <span style={{ color: colors.textPrimary, fontWeight: '900', fontSize: '1.2rem' }}>
                      ₹{selectedLedger.active_players > 0 
                          ? selectedLedger.cost_per_head 
                          : (selectedLedger.total_cost / (matches.find(m => m.id === selectedLedger.match_id)?.max_slots || 10)).toFixed(2)}
                    </span>
                  </div>

                  <button 
                    onClick={() => handleUPIPayment(
                      selectedLedger.active_players > 0 ? selectedLedger.cost_per_head : (selectedLedger.total_cost / 10).toFixed(2), 
                      selectedLedger.title
                    )}
                    style={{ marginTop: '1rem', backgroundColor: colors.accentRed, color: '#FFFFFF', padding: '1rem', borderRadius: '4px', border: 'none', fontSize: '1rem', fontWeight: '900', letterSpacing: '0.05em', cursor: 'pointer', transition: 'transform 0.1s' }}
                  >
                    PAY VIA UPI
                  </button>
                </div>
              </div>
            )}
          </div>
        </main>
      </div>
      
    </div>
  )
}

export default App