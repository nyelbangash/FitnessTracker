// src/pages/ProfilePage.jsx
import React from "react";
import { useAuth } from "../contexts/AuthContext";

export const ProfilePage = () => {
  const { user } = useAuth();

  return (
    <div className="min-h-screen bg-stone-50 text-stone-800 p-6">
      <h1 className="font-serif text-3xl mb-6">Profile</h1>

      <div className="bg-white border border-stone-200 rounded-lg p-6">
        <div className="mb-4">
          <p className="font-serif text-lg">{`${user.firstName} ${user.lastName}`}</p>
          <p className="text-stone-500">{user.username}</p>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="font-serif text-sm text-stone-500">Date of Birth</p>
            <p>{user.dateOfBirth}</p>
          </div>
          <div>
            <p className="font-serif text-sm text-stone-500">Height</p>
            <p>{user.height} cm</p>
          </div>
          <div>
            <p className="font-serif text-sm text-stone-500">Weight</p>
            <p>{user.weight} kg</p>
          </div>
        </div>
      </div>
    </div>
  );
};
