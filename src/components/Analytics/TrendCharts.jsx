import React from 'react';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, Area, AreaChart
} from 'recharts';
import { getTrendData } from '../../services/mockScamIntelligence';
import './TrendCharts.css';

const TrendCharts = () => {
  const data = getTrendData();

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="custom-tooltip glass-panel p-4">
          <p className="label font-bold mb-2">{`${label} - Insights`}</p>
          {payload.map((pld, index) => (
            <div key={index} className="flex justify-between gap-4 text-sm mb-1" style={{ color: pld.color }}>
              <span>{pld.name}:</span>
              <span className="font-bold">{pld.value}</span>
            </div>
          ))}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="trend-charts-container h-full w-full">
      <div className="chart-header mb-4 flex justify-between items-center">
        <h3 className="text-xl font-bold text-gradient">Scam Reports Trend</h3>
        <select className="bg-transparent border border-gray-600 text-white rounded p-1 text-sm outline-none">
          <option value="weekly">This Week</option>
          <option value="monthly">This Month</option>
        </select>
      </div>
      <div style={{ width: '100%', height: 300 }}>
        <ResponsiveContainer>
          <AreaChart
            data={data}
            margin={{ top: 10, right: 30, left: 0, bottom: 0 }}
          >
            <defs>
              <linearGradient id="colorReports" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#ef4444" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
              </linearGradient>
              <linearGradient id="colorPhishing" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#f97316" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#f97316" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <XAxis dataKey="day" stroke="#94a3b8" />
            <YAxis stroke="#94a3b8" />
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
            <Tooltip content={<CustomTooltip />} />
            <Legend wrapperStyle={{ paddingTop: '20px' }} />
            <Area type="monotone" dataKey="reports" name="Total Reports" stroke="#ef4444" fillOpacity={1} fill="url(#colorReports)" />
            <Area type="monotone" dataKey="phishing" name="Phishing Links" stroke="#f97316" fillOpacity={1} fill="url(#colorPhishing)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default TrendCharts;
