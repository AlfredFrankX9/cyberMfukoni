import React, { useState } from 'react';
import { getTrendingScams, getLiveAlerts, getBrandImpersonations } from '../../services/mockScamIntelligence';
import TrendCharts from '../Analytics/TrendCharts';
import KenyaHeatMap from '../Map/KenyaHeatMap';
import { ShieldAlert, TrendingUp, Activity, AlertTriangle, Shield, MessageSquareWarning } from 'lucide-react';
import './RadarDashboard.css';

const RadarDashboard = () => {
  const trendingScams = getTrendingScams();
  const liveAlerts = getLiveAlerts();
  const brandImpersonations = getBrandImpersonations();

  return (
    <div className="radar-dashboard container py-6">
      <header className="dashboard-header mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gradient flex items-center gap-2">
            <ShieldAlert size={32} className="text-red-500" />
            Kenya Scam Radar
          </h1>
          <p className="text-secondary mt-1">Real-time National Cyber Threat Intelligence</p>
        </div>
        <button className="btn btn-primary">
          <MessageSquareWarning size={18} />
          Report a Scam
        </button>
      </header>

      <div className="dashboard-grid">
        {/* Left Column: Alerts & Trending */}
        <div className="col-span-1 flex flex-col gap-6">
          <section className="glass-panel p-6 animate-slide-up" style={{ animationDelay: '0.1s' }}>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Activity className="text-cyan-500" /> Live Alerts
            </h2>
            <div className="live-alerts-stream">
              {liveAlerts.map(alert => (
                <div key={alert.id} className={`alert-item ${alert.type}`}>
                  <AlertTriangle size={16} />
                  <div className="alert-content">
                    <p className="text-sm">{alert.message}</p>
                    <span className="text-xs text-muted">{alert.time}</span>
                  </div>
                </div>
              ))}
            </div>
          </section>

          <section className="glass-panel p-6 animate-slide-up" style={{ animationDelay: '0.2s' }}>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <TrendingUp className="text-orange-500" /> Trending Scams
            </h2>
            <div className="trending-list flex flex-col gap-4">
              {trendingScams.map((scam, index) => (
                <div key={scam.id} className="trending-item flex justify-between items-center pb-4 border-b border-glass last:border-0 last:pb-0">
                  <div className="flex gap-4 items-center">
                    <span className="text-2xl font-bold text-muted w-6">#{index + 1}</span>
                    <div>
                      <h4 className="font-bold text-sm">{scam.name}</h4>
                      <div className="flex gap-2 items-center mt-1">
                        <span className={`badge ${scam.severity.toLowerCase()}`}>{scam.severity}</span>
                        <span className="text-xs text-secondary">{scam.reports} reports</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-bold text-gradient-cyan">Trend: {scam.score}</div>
                    <div className={`text-xs ${scam.growth.startsWith('+') ? 'text-red-400' : 'text-green-400'}`}>
                      {scam.growth}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* Center Column: Heat Map */}
        <div className="col-span-2 flex flex-col gap-6">
          <section className="glass-panel p-1 h-[450px] animate-slide-up" style={{ animationDelay: '0.3s' }}>
             <KenyaHeatMap />
          </section>

          <section className="glass-panel p-6 animate-slide-up h-[320px]" style={{ animationDelay: '0.4s' }}>
             <TrendCharts />
          </section>
        </div>

        {/* Right Column: Brand Tracker */}
        <div className="col-span-1 flex flex-col gap-6">
          <section className="glass-panel p-6 animate-slide-up" style={{ animationDelay: '0.5s' }}>
            <h2 className="text-xl font-bold mb-4 flex items-center gap-2">
              <Shield className="text-blue-500" /> Brand Tracker
            </h2>
            <p className="text-xs text-secondary mb-4">Most impersonated organizations this week.</p>
            <div className="brand-list flex flex-col gap-4">
              {brandImpersonations.map(brand => (
                <div key={brand.id} className="brand-item">
                  <div className="flex justify-between items-center mb-1">
                    <span className="font-bold text-sm">{brand.brand}</span>
                    <span className="text-xs text-red-400">{brand.growth}</span>
                  </div>
                  <div className="text-xs text-secondary flex justify-between">
                    <span>{brand.campaigns} campaigns</span>
                    <span>Top: {brand.topTactic}</span>
                  </div>
                  <div className="progress-bar mt-2">
                    <div className="progress-fill" style={{ width: `${Math.min(brand.campaigns * 5, 100)}%` }}></div>
                  </div>
                </div>
              ))}
            </div>
          </section>
          
          <section className="glass-panel p-6 rounded-xl flex items-center justify-center bg-cover bg-center h-48 animate-slide-up relative overflow-hidden" style={{ backgroundImage: "url('/images/alert_illustration.png')", animationDelay: '0.6s' }}>
             <div className="absolute inset-0 bg-black/60 backdrop-blur-[2px]"></div>
             <div className="relative z-10 text-center">
                <h3 className="text-lg font-bold text-white mb-2">Weekly Landscape Report</h3>
                <p className="text-xs text-gray-300 mb-4">AI analysis of the fastest growing threats.</p>
                <button className="btn btn-outline text-sm py-2 px-4">View Report</button>
             </div>
          </section>
        </div>
      </div>
    </div>
  );
};

export default RadarDashboard;
