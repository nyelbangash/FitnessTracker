import React from "react";

// Simple progress ring. value/max are unitless.
export const Ring = ({
  value = 0,
  max = 100,
  size = 64,
  stroke = 6,
  label,
  number,
  color = "var(--accent)",
  trackColor = "var(--border)",
}) => {
  const safeMax = max || 1;
  const ratio = Math.max(0, Math.min(1.2, value / safeMax));
  const r = (size - stroke) / 2;
  const C = 2 * Math.PI * r;
  const dash = ratio * C;

  return (
    <div className="inline-flex flex-col items-center gap-1">
      <svg width={size} height={size} className="block">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={trackColor}
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeDasharray={`${dash} ${C}`}
          strokeLinecap="round"
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
        {number !== undefined && (
          <text
            x="50%"
            y="50%"
            dominantBaseline="central"
            textAnchor="middle"
            fontFamily="var(--font-mono)"
            fontSize={size / 4}
            fill="var(--text)"
          >
            {number}
          </text>
        )}
      </svg>
      {label && (
        <div className="text-[10px] uppercase tracking-widest text-muted">
          {label}
        </div>
      )}
    </div>
  );
};
