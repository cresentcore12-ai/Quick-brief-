#!/bin/bash

# This will be split due to size - creating the comprehensive main page
cat > pages/index.tsx << 'ENDFILE'
import { useState, useEffect } from 'react';
import Head from 'next/head';
import { generateBrief, BriefData } from '../lib/briefGenerator';
import { connectionManager } from '../lib/connections';
import { analyticsManager } from '../lib/analytics';

export default function Home() {
  const [formData, setFormData] = useState<BriefData>({
    title: '',
    type: '',
    duration: 30,
    attendees: '',
    goal: '',
    context: '',
  });

  const [brief, setBrief] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<'generator' | 'analytics' | 'calendar'>('generator');
  const [connections, setConnections] = useState({ claude: false, calendar: false });
  const [calendarMeetings, setCalendarMeetings] = useState<any[]>([]);
  const [analytics, setAnalytics] = useState<any>(null);

  useEffect(() => {
    updateConnections();
    updateAnalytics();
  }, []);

  const updateConnections = () => {
    const status = connectionManager.getStatus();
    setConnections(status);
    if (status.calendar) {
      setCalendarMeetings(connectionManager.getCalendarMeetings());
    }
  };

  const updateAnalytics = () => {
    setAnalytics(analyticsManager.getAnalytics());
  };

  const handleConnectClaude = () => {
    // In production, this would open OAuth flow
    // For now, simulated connection
    if (confirm('Connect your Claude account?\n\nThis will allow QuickBrief to generate better, more personalized briefs.')) {
      connectionManager.connectClaude();
      updateConnections();
      showToast('✅ Claude connected successfully!');
    }
  };

  const handleConnectCalendar = () => {
    // In production, this would open Google OAuth flow
    // For now, simulated connection with sample meetings
    if (confirm('Connect Google Calendar?\n\nThis will let you import meetings directly into QuickBrief.')) {
      connectionManager.connectCalendar();
      updateConnections();
      showToast('✅ Calendar connected! Loading your meetings...');
    }
  };

  const handleDisconnect = (type: 'claude' | 'calendar') => {
    if (confirm(`Disconnect ${type === 'claude' ? 'Claude' : 'Google Calendar'}?`)) {
      if (type === 'claude') {
        connectionManager.disconnectClaude();
      } else {
        connectionManager.disconnectCalendar();
      }
      updateConnections();
      showToast(`${type === 'claude' ? 'Claude' : 'Calendar'} disconnected`);
    }
  };

  const loadMeetingFromCalendar = (meeting: any) => {
    setFormData({
      title: meeting.title,
      type: meeting.type || 'other',
      duration: meeting.duration || 30,
      attendees: meeting.attendees || '',
      goal: '',
      context: '',
    });
    setActiveTab('generator');
    showToast('Meeting loaded! Add your goal and generate.');
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.title || !formData.type || !formData.goal) {
      alert('Please fill in all required fields (*)');
      return;
    }

    setLoading(true);

    setTimeout(() => {
      const generated = generateBrief(formData);
      setBrief(generated);

      // Save to history
      const userData = JSON.parse(localStorage.getItem('quickbrief_user_data') || '{"briefHistory":[]}');
      userData.briefHistory = userData.briefHistory || [];
      userData.briefHistory.push({
        id: 'brief_' + Date.now(),
        timestamp: new Date().toISOString(),
        title: formData.title,
        type: formData.type,
        duration: formData.duration,
        goal: formData.goal,
      });
      if (userData.briefHistory.length > 50) {
        userData.briefHistory = userData.briefHistory.slice(-50);
      }
      localStorage.setItem('quickbrief_user_data', JSON.stringify(userData));

      updateAnalytics();
      setLoading(false);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }, 1800);
  };

  const copyText = (text: string) => {
    navigator.clipboard.writeText(text).then(() => {
      showToast('✅ Copied to clipboard!');
    });
  };

  const showToast = (message: string) => {
    const toast = document.createElement('div');
    toast.className = 'fixed bottom-4 right-4 bg-blue-600 text-white px-6 py-3 rounded-lg shadow-xl z-50';
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transition = 'opacity 0.3s';
      setTimeout(() => toast.remove(), 300);
    }, 2500);
  };

  const downloadData = () => {
    const userData = localStorage.getItem('quickbrief_user_data') || '{}';
    const blob = new Blob([userData], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'quickbrief-data.json';
    a.click();
  };

  if (brief) {
    return (
      <>
        <Head><title>{formData.title} - QuickBrief Pro</title></Head>
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
          <div className="max-w-5xl mx-auto">
            <div className="bg-white rounded-xl shadow-lg p-6 mb-6">
              <div className="flex justify-between items-center flex-wrap gap-4">
                <div>
                  <h1 className="text-3xl font-bold text-gray-900">{formData.title}</h1>
                  <p className="text-gray-600 mt-1">{formData.duration} min • {formData.type}</p>
                  {formData.attendees && (
                    <p className="text-sm text-gray-500 mt-1">👥 {formData.attendees}</p>
                  )}
                </div>
                <button onClick={() => { setBrief(null); setFormData({ title: '', type: '', duration: 30, attendees: '', goal: '', context: '' }); }} className="btn btn-secondary">
                  ← Back
                </button>
              </div>
            </div>

            <div className="bg-green-50 border-l-4 border-green-500 p-4 mb-6 rounded">
              <div className="flex items-center">
                <svg className="w-6 h-6 text-green-500 mr-3" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
                </svg>
                <div>
                  <p className="font-semibold text-green-900">✅ Your brief is ready!</p>
                  <p className="text-green-700 text-sm">Generated with {connections.claude ? 'Claude AI' : 'Smart Templates'} • Ready to use</p>
                </div>
              </div>
            </div>

            {[
              { title: '📋 Meeting Agenda', content: brief.agenda, key: 'agenda' },
              { title: '💡 Key Talking Points', content: brief.talkingPoints, key: 'points' },
              { title: '🛡️ Potential Objections', content: brief.objections, key: 'objections' },
              { title: '❓ Strategic Questions', content: brief.questions, key: 'questions' },
              { title: '✅ Next Steps', content: brief.nextSteps, key: 'steps' },
            ].map((section, idx) => (
              <div key={idx} className="card mb-6">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-2xl font-bold text-gray-900">{section.title}</h2>
                  <button onClick={() => copyText(Array.isArray(section.content) ? section.content.join('\n') : section.content)} className="btn btn-secondary text-sm">
                    📋 Copy
                  </button>
                </div>
                {Array.isArray(section.content) ? (
                  <ul className="space-y-3">
                    {section.content.map((item: string, i: number) => (
                      <li key={i} className="flex items-start">
                        <span className="text-blue-600 font-bold mr-3">•</span>
                        <span className="text-gray-700">{item}</span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <pre className="whitespace-pre-wrap text-gray-700 font-sans leading-relaxed">{section.content}</pre>
                )}
              </div>
            ))}

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
              <button onClick={() => {
                const all = `${formData.title}\n\n${brief.agenda}\n\nTalking Points:\n${brief.talkingPoints.join('\n')}\n\nObjections:\n${brief.objections.join('\n\n')}\n\nQuestions:\n${brief.questions.join('\n')}\n\nNext Steps:\n${brief.nextSteps.join('\n')}`;
                copyText(all);
              }} className="btn btn-primary">📋 Copy All</button>
              <button onClick={() => window.print()} className="btn btn-secondary">🖨️ Print/PDF</button>
              <button onClick={() => setBrief(null)} className="btn btn-secondary">🔄 New Brief</button>
            </div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Head><title>QuickBrief Pro - AI Meeting Preparation</title></Head>
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <nav className="bg-white shadow-sm">
          <div className="max-w-7xl mx-auto px-4 py-4">
            <div className="flex justify-between items-center flex-wrap gap-4">
              <div className="flex items-center space-x-3">
                <div className="w-12 h-12 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg">
                  <span className="text-white font-bold text-2xl">Q</span>
                </div>
                <div>
                  <span className="text-2xl font-bold text-gray-900">QuickBrief Pro</span>
                  <p className="text-xs text-gray-500">AI-Powered Meeting Preparation</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <button onClick={downloadData} className="text-sm text-gray-600 hover:text-gray-900">📥</button>
                <a href="mailto:sociaro.io@gmail.com" className="text-sm text-blue-600 hover:text-blue-800 font-semibold">📧 Contact</a>
              </div>
            </div>
          </div>
        </nav>

        <div className="max-w-7xl mx-auto px-4 py-8">
          {/* Tabs */}
          <div className="flex space-x-2 mb-8 overflow-x-auto">
            {[
              { id: 'generator', label: '⚡ Brief Generator', icon: '📝' },
              { id: 'calendar', label: '📅 Calendar', icon: '🗓️' },
              { id: 'analytics', label: '📊 Analytics', icon: '📈' },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`px-6 py-3 rounded-lg font-semibold transition-all ${
                  activeTab === tab.id
                    ? 'bg-blue-600 text-white shadow-lg'
                    : 'bg-white text-gray-700 hover:bg-gray-50'
                }`}
              >
                {tab.icon} {tab.label}
              </button>
            ))}
          </div>

          {/* Connection Status */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
            <div className={`card ${connections.claude ? 'border-2 border-green-500' : 'border-2 border-gray-300'}`}>
              <div className="flex justify-between items-center">
                <div className="flex items-center space-x-3">
                  <div className={`w-12 h-12 rounded-full flex items-center justify-center ${connections.claude ? 'bg-green-100' : 'bg-gray-100'}`}>
                    <span className="text-2xl">{connections.claude ? '✅' : '🤖'}</span>
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Claude Account</h3>
                    <p className="text-sm text-gray-600">
                      {connections.claude ? 'Connected • Better AI briefs' : 'Not connected'}
                    </p>
                  </div>
                </div>
                {connections.claude ? (
                  <button onClick={() => handleDisconnect('claude')} className="btn btn-secondary text-sm">Disconnect</button>
                ) : (
                  <button onClick={handleConnectClaude} className="btn btn-success text-sm">Connect</button>
                )}
              </div>
            </div>

            <div className={`card ${connections.calendar ? 'border-2 border-green-500' : 'border-2 border-gray-300'}`}>
              <div className="flex justify-between items-center">
                <div className="flex items-center space-x-3">
                  <div className={`w-12 h-12 rounded-full flex items-center justify-center ${connections.calendar ? 'bg-green-100' : 'bg-gray-100'}`}>
                    <span className="text-2xl">{connections.calendar ? '✅' : '📅'}</span>
                  </div>
                  <div>
                    <h3 className="font-bold text-lg">Google Calendar</h3>
                    <p className="text-sm text-gray-600">
                      {connections.calendar ? `${calendarMeetings.length} upcoming meetings` : 'Not connected'}
                    </p>
                  </div>
                </div>
                {connections.calendar ? (
                  <button onClick={() => handleDisconnect('calendar')} className="btn btn-secondary text-sm">Disconnect</button>
                ) : (
                  <button onClick={handleConnectCalendar} className="btn btn-success text-sm">Connect</button>
                )}
              </div>
            </div>
          </div>

          {/* Generator Tab */}
          {activeTab === 'generator' && (
            <form onSubmit={handleSubmit} className="card max-w-4xl mx-auto">
              <h2 className="text-2xl font-bold mb-6">Create Your Meeting Brief</h2>

              <div className="mb-5">
                <label className="block text-sm font-bold text-gray-700 mb-2">Meeting Title *</label>
                <input type="text" className="input" placeholder="e.g., Q1 Budget Review" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} required />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-5">
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-2">Type *</label>
                  <select className="input" value={formData.type} onChange={(e) => setFormData({ ...formData, type: e.target.value })} required>
                    <option value="">Select...</option>
                    <option value="sales">🎯 Sales</option>
                    <option value="negotiation">🤝 Negotiation</option>
                    <option value="review">📊 Review</option>
                    <option value="planning">📅 Planning</option>
                    <option value="client">👔 Client</option>
                    <option value="interview">💼 Interview</option>
                    <option value="standup">⚡ Standup</option>
                    <option value="1on1">👥 1-on-1</option>
                    <option value="other">📋 Other</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-bold text-gray-700 mb-2">Duration</label>
                  <select className="input" value={formData.duration} onChange={(e) => setFormData({ ...formData, duration: Number(e.target.value) })}>
                    <option value="15">15 min</option>
                    <option value="30">30 min</option>
                    <option value="45">45 min</option>
                    <option value="60">1 hour</option>
                    <option value="90">90 min</option>
                    <option value="120">2 hours</option>
                  </select>
                </div>
              </div>

              <div className="mb-5">
                <label className="block text-sm font-bold text-gray-700 mb-2">Attendees (optional)</label>
                <input type="text" className="input" placeholder="e.g., CFO, Marketing Team" value={formData.attendees} onChange={(e) => setFormData({ ...formData, attendees: e.target.value })} />
              </div>

              <div className="mb-5">
                <label className="block text-sm font-bold text-gray-700 mb-2">Your Goal *</label>
                <textarea className="input min-h-[100px]" placeholder="e.g., Get approval for $50K budget" value={formData.goal} onChange={(e) => setFormData({ ...formData, goal: e.target.value })} required />
              </div>

              <div className="mb-6">
                <label className="block text-sm font-bold text-gray-700 mb-2">Context (optional)</label>
                <textarea className="input min-h-[100px]" placeholder="Background info..." value={formData.context} onChange={(e) => setFormData({ ...formData, context: e.target.value })} />
              </div>

              <button type="submit" disabled={loading} className="btn btn-primary w-full text-lg py-4">
                {loading ? '⏳ Generating...' : '⚡ Generate Brief'}
              </button>
            </form>
          )}

          {/* Calendar Tab */}
          {activeTab === 'calendar' && (
            <div className="max-w-4xl mx-auto">
              {connections.calendar ? (
                <div>
                  <h2 className="text-2xl font-bold mb-6">📅 Upcoming Meetings</h2>
                  {calendarMeetings.length === 0 ? (
                    <div className="card text-center py-12">
                      <p className="text-gray-600">No upcoming meetings found</p>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {calendarMeetings.map((meeting) => (
                        <div key={meeting.id} className="card hover:shadow-xl transition-shadow cursor-pointer" onClick={() => loadMeetingFromCalendar(meeting)}>
                          <div className="flex justify-between items-start">
                            <div className="flex-1">
                              <h3 className="font-bold text-lg mb-2">{meeting.title}</h3>
                              <div className="space-y-1 text-sm text-gray-600">
                                <p>🕐 {new Date(meeting.start).toLocaleString()}</p>
                                <p>⏱️ {meeting.duration} minutes</p>
                                {meeting.attendees && <p>👥 {meeting.attendees}</p>}
                              </div>
                            </div>
                            <button className="btn btn-primary text-sm">Load →</button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <div className="card text-center py-12">
                  <div className="text-6xl mb-4">📅</div>
                  <h3 className="text-xl font-bold mb-2">Connect Google Calendar</h3>
                  <p className="text-gray-600 mb-6">Import your meetings and generate briefs instantly</p>
                  <button onClick={handleConnectCalendar} className="btn btn-success">Connect Calendar</button>
                </div>
              )}
            </div>
          )}

          {/* Analytics Tab */}
          {activeTab === 'analytics' && analytics && (
            <div className="max-w-6xl mx-auto">
              <h2 className="text-2xl font-bold mb-6">📊 Your Meeting Analytics</h2>
              
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
                {[
                  { label: 'Total Meetings', value: analytics.totalMeetings, color: 'blue' },
                  { label: 'This Week', value: analytics.thisWeek, color: 'green' },
                  { label: 'This Month', value: analytics.thisMonth, color: 'purple' },
                  { label: 'Hours Saved', value: `${analytics.totalHoursSaved}h`, color: 'orange' },
                ].map((stat, i) => (
                  <div key={i} className="card text-center">
                    <div className={`text-3xl font-bold text-${stat.color}-600 mb-1`}>{stat.value}</div>
                    <div className="text-sm text-gray-600">{stat.label}</div>
                  </div>
                ))}
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="card">
                  <h3 className="font-bold text-lg mb-4">📈 Performance</h3>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span>Avg Duration:</span>
                      <span className="font-bold">{analytics.avgDuration} min</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Success Rate:</span>
                      <span className="font-bold text-green-600">{analytics.successRate}%</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Most Productive:</span>
                      <span className="font-bold">{analytics.mostProductiveDay}</span>
                    </div>
                  </div>
                </div>

                <div className="card">
                  <h3 className="font-bold text-lg mb-4">📋 By Type</h3>
                  <div className="space-y-2">
                    {Object.entries(analytics.byType).map(([type, count]) => (
                      <div key={type} className="flex justify-between items-center">
                        <span className="capitalize">{type}:</span>
                        <span className="badge badge-success">{count}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {analytics.totalMeetings === 0 && (
                <div className="card text-center py-12 mt-8">
                  <p className="text-gray-600">Generate your first brief to see analytics!</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {loading && (
        <div className="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-10 max-w-md text-center shadow-2xl">
            <div className="w-20 h-20 border-4 border-blue-600 border-t-transparent rounded-full animate-spin mx-auto mb-6"></div>
            <h3 className="text-2xl font-bold mb-3">Generating Your Brief</h3>
            <p className="text-gray-600">{connections.claude ? 'Using Claude AI for better results...' : 'Creating professional brief...'}</p>
          </div>
        </div>
      )}
    </>
  );
}
ENDFILE

echo "✅ Main app created!"
