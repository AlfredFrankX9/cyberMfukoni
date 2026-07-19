export const getTrendingScams = () => [
  {
    id: 1,
    name: "Fake M-Pesa Reversal",
    score: 98,
    growth: "+15%",
    reports: 1245,
    firstSeen: "2026-06-01",
    lastReported: "Just now",
    category: "Financial",
    severity: "Critical",
  },
  {
    id: 2,
    name: "Fake Job Recruitment",
    score: 94,
    growth: "+22%",
    reports: 890,
    firstSeen: "2026-05-15",
    lastReported: "5 mins ago",
    category: "Employment",
    severity: "High",
  },
  {
    id: 3,
    name: "KRA Tax Refund Scam",
    score: 90,
    growth: "+30%",
    reports: 650,
    firstSeen: "2026-06-05",
    lastReported: "12 mins ago",
    category: "Government",
    severity: "Critical",
  },
  {
    id: 4,
    name: "WhatsApp Verification Scam",
    score: 87,
    growth: "+5%",
    reports: 512,
    firstSeen: "2026-04-20",
    lastReported: "1 hr ago",
    category: "Social Media",
    severity: "High",
  },
  {
    id: 5,
    name: "Betting Winning Scam",
    score: 82,
    growth: "-2%",
    reports: 430,
    firstSeen: "2026-03-10",
    lastReported: "2 hrs ago",
    category: "Lottery",
    severity: "Moderate",
  },
];

export const getLiveAlerts = () => [
  { id: 101, message: "Spike detected in fake M-Pesa messages", time: "Just now", type: "warning" },
  { id: 102, message: "New fake Equity Bank campaign detected", time: "10 mins ago", type: "danger" },
  { id: 103, message: "WhatsApp takeover scam increasing in Nairobi", time: "45 mins ago", type: "danger" },
  { id: 104, message: "Fake KRA refund links spreading via SMS", time: "2 hours ago", type: "warning" },
];

export const getTrendData = () => [
  { day: 'Mon', reports: 400, phishing: 240, impersonation: 160 },
  { day: 'Tue', reports: 450, phishing: 260, impersonation: 190 },
  { day: 'Wed', reports: 520, phishing: 300, impersonation: 220 },
  { day: 'Thu', reports: 610, phishing: 350, impersonation: 260 },
  { day: 'Fri', reports: 800, phishing: 500, impersonation: 300 }, // Spike day
  { day: 'Sat', reports: 750, phishing: 460, impersonation: 290 },
  { day: 'Sun', reports: 720, phishing: 440, impersonation: 280 },
];

export const getBrandImpersonations = () => [
  { id: 1, brand: "Safaricom", campaigns: 12, growth: "+8%", topTactic: "Fake SMS Rewards" },
  { id: 2, brand: "Equity Bank", campaigns: 8, growth: "+15%", topTactic: "Account Verification Call" },
  { id: 3, brand: "KRA", campaigns: 5, growth: "+40%", topTactic: "Tax Refund Links" },
  { id: 4, brand: "M-Pesa", campaigns: 18, growth: "+2%", topTactic: "Reversal Request" },
  { id: 5, brand: "KCB", campaigns: 4, growth: "-5%", topTactic: "Loan Approval SMS" },
];

// Heat map mock data for React-Leaflet
export const getHeatMapData = () => [
  // lat, lng, intensity
  [-1.2921, 36.8219, 0.9], // Nairobi (High)
  [-4.0435, 39.6682, 0.7], // Mombasa
  [-0.1022, 34.7617, 0.5], // Kisumu
  [-0.3031, 36.0800, 0.4], // Nakuru
  [0.5143, 35.2698, 0.3],  // Eldoret
];
