// src/components/layout/AppLayout.jsx
import React from "react";
import { Outlet } from "react-router-dom";
import { Navigation } from "./Navigation";

export const AppLayout = () => {
  return (
    <div className="min-h-screen bg-stone-50">
      <Navigation />
      <main>
        <Outlet />
      </main>
    </div>
  );
};
