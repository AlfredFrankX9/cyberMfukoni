import React from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { getHeatMapData } from '../../services/mockScamIntelligence';
import './KenyaHeatMap.css';

const KenyaHeatMap = () => {
  const data = getHeatMapData();
  // Center of Kenya
  const position = [0.0236, 37.9062];

  const getColor = (intensity) => {
    if (intensity >= 0.8) return 'var(--status-critical)';
    if (intensity >= 0.6) return 'var(--status-high)';
    if (intensity >= 0.4) return 'var(--status-moderate)';
    return 'var(--status-low)';
  };

  return (
    <div className="map-wrapper glass-panel relative overflow-hidden h-full">
      <div className="absolute top-4 left-4 z-[1000] pointer-events-none">
        <h3 className="text-xl font-bold text-gradient text-shadow">Active Threat Zones</h3>
      </div>
      <MapContainer center={position} zoom={6} className="h-full w-full custom-map" zoomControl={false}>
        {/* Dark theme tile layer */}
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
        />
        {data.map((point, index) => {
          const [lat, lng, intensity] = point;
          const color = getColor(intensity);
          return (
            <CircleMarker
              key={index}
              center={[lat, lng]}
              pathOptions={{
                color: color,
                fillColor: color,
                fillOpacity: 0.6,
                weight: 2
              }}
              radius={intensity * 30}
              className={intensity > 0.7 ? "animate-pulse-glow" : ""}
            >
              <Popup className="custom-popup">
                <div className="text-sm font-bold mb-1">Threat Level: {Math.round(intensity * 100)}%</div>
                <div className="text-xs text-gray-300">Click to view local reports</div>
              </Popup>
            </CircleMarker>
          );
        })}
      </MapContainer>
      <div className="absolute bottom-4 left-4 z-[1000] flex gap-2 text-xs bg-black/50 p-2 rounded pointer-events-none">
         <span className="flex items-center gap-1"><div className="w-3 h-3 rounded-full bg-green-500" style={{backgroundColor: 'var(--status-low)'}}></div> Low</span>
         <span className="flex items-center gap-1"><div className="w-3 h-3 rounded-full bg-yellow-500" style={{backgroundColor: 'var(--status-moderate)'}}></div> Mod</span>
         <span className="flex items-center gap-1"><div className="w-3 h-3 rounded-full bg-orange-500" style={{backgroundColor: 'var(--status-high)'}}></div> High</span>
         <span className="flex items-center gap-1"><div className="w-3 h-3 rounded-full bg-red-500" style={{backgroundColor: 'var(--status-critical)'}}></div> Critical</span>
      </div>
    </div>
  );
};

export default KenyaHeatMap;
