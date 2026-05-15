// src/contexts/AuthContext.js
import React, { createContext, useContext, useState, useCallback } from "react";
import * as api from "../api";

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(() => {
    const savedUser = localStorage.getItem("user");
    return savedUser ? JSON.parse(savedUser) : null;
  });

  const [token, setToken] = useState(() => localStorage.getItem("token"));

  const persistUser = (userData, tokenValue) => {
    if (userData) {
      // Keep `username` populated so legacy display code (`user.username`) keeps
      // working — it's just an alias for email in the new backend.
      const enriched = {
        ...userData,
        username: userData.email,
      };
      setUser(enriched);
      localStorage.setItem("user", JSON.stringify(enriched));
    } else {
      setUser(null);
      localStorage.removeItem("user");
    }

    if (tokenValue) {
      setToken(tokenValue);
      localStorage.setItem("token", tokenValue);
    } else if (tokenValue === null) {
      setToken(null);
      localStorage.removeItem("token");
    }
  };

  const login = useCallback(async (emailOrUsername, password) => {
    const { profile, token: newToken } = await api.login({
      email: emailOrUsername,
      password,
    });
    persistUser(profile, newToken);
    return profile;
  }, []);

  const signup = useCallback(async (profileData) => {
    const result = await api.createProfile(profileData);
    if (result.user && result.token) {
      persistUser(result.user, result.token);
    }
    return result;
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.logout();
    } catch (_) {
      // ignore
    }
    persistUser(null, null);
    localStorage.removeItem("username"); // legacy key cleanup
  }, []);

  return (
    <AuthContext.Provider value={{ user, token, login, signup, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
