import React from "react";

// Horizontal progress bar that overshoots to a warn color past 100%.
export const Bar = ({
  value = 0,
  max = 100,
  height = 4,
  color = "var(--accent)",
  trackColor = "var(--border)",
  overflowColor = "var(--warn)",
}) => {
  const safeMax = max || 1;
  const pct = (value / safeMax) * 100;
  const cap = Math.min(pct, 100);
  const overshoot = Math.max(0, pct - 100);

  return (
    <div
      className="w-full rounded overflow-hidden flex"
      style={{ height, background: trackColor }}
    >
      <div style={{ width: `${cap}%`, background: color }} />
      {overshoot > 0 && (
        <div
          style={{
            width: `${Math.min(overshoot, 30)}%`,
            background: overflowColor,
          }}
        />
      )}
    </div>
  );
};
