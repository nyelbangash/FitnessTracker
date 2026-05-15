import React from "react";

export const Card = ({ children, raised = false, className = "", ...rest }) => (
  <div
    className={`${raised ? "gb-card-2" : "gb-card"} ${className}`}
    {...rest}
  >
    {children}
  </div>
);

export const CardHeader = ({ title, subtitle, action, className = "" }) => (
  <div className={`flex items-baseline justify-between px-5 pt-4 ${className}`}>
    <div>
      {title && <h3 className="text-lg leading-tight">{title}</h3>}
      {subtitle && (
        <div className="text-muted text-sm mt-0.5">{subtitle}</div>
      )}
    </div>
    {action}
  </div>
);

export const CardBody = ({ children, className = "" }) => (
  <div className={`px-5 py-4 ${className}`}>{children}</div>
);

export const CardFooter = ({ children, className = "" }) => (
  <div
    className={`px-5 py-3 border-t border-line text-sm text-muted ${className}`}
  >
    {children}
  </div>
);
