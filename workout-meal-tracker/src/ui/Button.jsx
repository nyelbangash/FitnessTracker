import React from "react";

// Variants:
//   primary  — accent bg, used for the canonical "do it" action
//   default  — surface bg with a thin border
//   ghost    — no surface, hover gets a subtle bg
//   danger   — for destructive actions
// Sizes: sm / md / lg / xl (xl is the active-workout complete-set hero)

const sizes = {
  sm: "px-2.5 py-1 text-xs",
  md: "px-3.5 py-1.5 text-sm",
  lg: "px-5 py-2 text-base",
  xl: "px-8 py-4 text-lg",
};

export const Button = ({
  children,
  variant = "default",
  size = "md",
  full = false,
  className = "",
  type = "button",
  ...rest
}) => {
  const sizeClass = sizes[size] || sizes.md;
  const fullClass = full ? "w-full justify-center" : "";

  let variantStyle = {};
  let variantClass =
    "inline-flex items-center gap-2 rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed focus:outline-none focus-visible:ring-2";

  if (variant === "primary") {
    variantStyle = { background: "var(--accent)", color: "var(--accent-text)" };
    variantClass += " hover:opacity-90 focus-visible:ring-offset-2";
  } else if (variant === "ghost") {
    variantStyle = { color: "var(--text)" };
    variantClass += " hover:bg-surface-2";
  } else if (variant === "danger") {
    variantStyle = { background: "var(--bad)", color: "white" };
    variantClass += " hover:opacity-90";
  } else {
    variantStyle = {
      background: "var(--surface)",
      color: "var(--text)",
      borderWidth: "1px",
      borderColor: "var(--border)",
    };
    variantClass += " hover:bg-surface-2";
  }

  return (
    <button
      type={type}
      className={`${variantClass} ${sizeClass} ${fullClass} ${className}`}
      style={variantStyle}
      {...rest}
    >
      {children}
    </button>
  );
};
