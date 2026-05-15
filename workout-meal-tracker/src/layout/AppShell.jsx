import React, { useEffect, useState, useCallback } from "react";
import { NavLink, useNavigate, Outlet } from "react-router-dom";
import {
  Home,
  Dumbbell,
  Apple,
  TrendingUp,
  User as UserIcon,
  Command,
  Plus,
  Camera,
} from "lucide-react";
import { useAuth } from "../contexts/AuthContext";
import { useTheme } from "../theme/ThemeContext";
import { themes } from "../theme/themes";
import { CommandPalette } from "./CommandPalette";
import { StatusPill } from "./StatusPill";

const navItems = [
  { to: "/", label: "Today", Icon: Home },
  { to: "/train", label: "Train", Icon: Dumbbell },
  { to: "/eat", label: "Eat", Icon: Apple },
  { to: "/progress", label: "Progress", Icon: TrendingUp },
  { to: "/you", label: "You", Icon: UserIcon },
];

export const AppShell = () => {
  const { user, logout } = useAuth();
  const { themeId } = useTheme();
  const [paletteOpen, setPaletteOpen] = useState(false);
  const navigate = useNavigate();

  const openPalette = useCallback(() => setPaletteOpen(true), []);

  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setPaletteOpen(true);
      }
      if (e.key === "Escape") setPaletteOpen(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  const today = new Date().toLocaleDateString(undefined, {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="flex min-h-screen bg-bg">
      {/* Sidebar (desktop) */}
      <aside
        className="hidden md:flex flex-col w-56 shrink-0 border-r"
        style={{ borderColor: "var(--border)", background: "var(--surface)" }}
      >
        <div className="px-5 pt-6 pb-4">
          <div className="font-serif-h text-2xl tracking-tight">Gym Bro</div>
          <div className="text-xs text-muted mt-0.5">{themes[themeId]?.name}</div>
        </div>

        <nav className="flex-1 px-2 mt-2 space-y-0.5">
          {navItems.map(({ to, label, Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === "/"}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded text-sm transition-colors ${
                  isActive ? "" : "hover:bg-surface-2"
                }`
              }
              style={({ isActive }) => ({
                background: isActive ? "var(--surface-2)" : "transparent",
                color: isActive ? "var(--text)" : "var(--text-muted)",
                fontWeight: isActive ? 500 : 400,
              })}
            >
              <Icon size={16} />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="px-3 py-4 border-t border-line">
          <button
            onClick={openPalette}
            className="flex items-center gap-2 w-full px-3 py-2 rounded text-sm text-muted hover:bg-surface-2"
          >
            <Command size={14} />
            <span>Quick action</span>
            <kbd
              className="ml-auto text-[10px] px-1.5 py-0.5 rounded"
              style={{
                background: "var(--surface-2)",
                border: "1px solid var(--border)",
              }}
            >
              ⌘K
            </kbd>
          </button>
          {user && (
            <button
              onClick={logout}
              className="w-full text-left px-3 py-1.5 mt-1 rounded text-xs text-muted hover:bg-surface-2"
            >
              {user.email} · sign out
            </button>
          )}
        </div>
      </aside>

      {/* Main column */}
      <div className="flex-1 flex flex-col min-w-0">
        <header
          className="flex items-center justify-between px-4 md:px-6 py-3 border-b sticky top-0 z-10"
          style={{ borderColor: "var(--border)", background: "var(--bg)" }}
        >
          <div className="font-serif-h text-lg md:hidden">Gym Bro</div>
          <div className="hidden md:block text-sm text-muted">{today}</div>
          <div className="flex items-center gap-2 md:gap-3">
            <StatusPill />
            <button
              onClick={openPalette}
              className="hidden md:inline-flex items-center gap-1.5 text-xs px-2 py-1 rounded text-muted hover:bg-surface-2"
              title="Quick action (⌘K)"
            >
              <Plus size={14} />
              Add
            </button>
          </div>
        </header>

        <main
          className="flex-1 px-4 md:px-6 py-4 md:py-6 overflow-y-auto pb-32 md:pb-6"
        >
          <Outlet />
        </main>
      </div>

      {/* Floating camera action button (mobile only) — fastest path to log a meal */}
      <button
        onClick={() => navigate("/eat/log?camera=1")}
        className="md:hidden fixed right-4 z-30 rounded-full shadow-lg flex items-center justify-center"
        style={{
          bottom: "calc(env(safe-area-inset-bottom, 0px) + 80px)",
          background: "var(--accent)",
          color: "var(--accent-text)",
          width: 56,
          height: 56,
          boxShadow: "0 8px 24px rgba(0,0,0,0.25)",
        }}
        aria-label="Snap a meal"
      >
        <Camera size={22} />
      </button>

      {/* Bottom tab bar (mobile) */}
      <nav
        className="md:hidden fixed bottom-0 left-0 right-0 z-20 border-t flex"
        style={{
          background: "var(--surface)",
          borderColor: "var(--border)",
          paddingBottom: "env(safe-area-inset-bottom, 0px)",
        }}
      >
        {navItems.map(({ to, label, Icon }) => (
          <NavLink
            key={to}
            to={to}
            end={to === "/"}
            className="flex-1 flex flex-col items-center justify-center gap-0.5 py-2.5 transition-colors"
            style={({ isActive }) => ({
              color: isActive ? "var(--accent)" : "var(--text-muted)",
            })}
          >
            <Icon size={20} />
            <span className="text-[10px] uppercase tracking-wide">{label}</span>
          </NavLink>
        ))}
      </nav>

      <CommandPalette
        open={paletteOpen}
        onClose={() => setPaletteOpen(false)}
        navigate={navigate}
      />
    </div>
  );
};
