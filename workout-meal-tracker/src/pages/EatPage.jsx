import React from "react";
import { NavLink, Outlet } from "react-router-dom";

const subnav = [
  { to: "/eat", label: "Today", end: true },
  { to: "/eat/log", label: "Log meal" },
  { to: "/eat/history", label: "History" },
  { to: "/eat/favorites", label: "Favorites" },
];

export const EatPage = () => (
  <div className="max-w-5xl mx-auto space-y-6">
    <nav className="flex items-center gap-1 border-b" style={{ borderColor: "var(--border)" }}>
      {subnav.map((item) => (
        <NavLink
          key={item.to}
          to={item.to}
          end={item.end}
          className="px-3 py-2 text-sm transition-colors"
          style={({ isActive }) => ({
            color: isActive ? "var(--text)" : "var(--text-muted)",
            borderBottom: isActive ? "2px solid var(--accent)" : "2px solid transparent",
            marginBottom: "-1px",
            fontWeight: isActive ? 500 : 400,
          })}
        >
          {item.label}
        </NavLink>
      ))}
    </nav>
    <Outlet />
  </div>
);
