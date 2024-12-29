// src/pages/SignupPage.jsx
import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Dumbbell } from "lucide-react";
import * as api from "../api";

export const SignupPage = () => {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [height, setHeight] = useState("");
  const [weight, setWeight] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await api.createProfile({
        firstName,
        lastName,
        username,
        password,
        dateOfBirth,
        height: parseFloat(height),
        weight: parseFloat(weight),
      });
      navigate("/login");
    } catch (error) {
      setError("Failed to create account");
    }
  };

  return (
    <div className="min-h-screen bg-stone-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <Dumbbell className="mx-auto h-12 w-12 text-stone-800" />
        <h2 className="mt-6 text-center text-3xl font-serif text-stone-800">
          Create your FitnessTracker account
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <form className="space-y-6" onSubmit={handleSubmit}>
            {error && (
              <div className="p-3 rounded-lg bg-red-50 text-red-700 text-sm">
                {error}
              </div>
            )}

            {/* Form fields */}
            <div className="grid grid-cols-2 gap-6">
              <div>
                <label
                  htmlFor="firstName"
                  className="block text-sm font-serif text-stone-700"
                >
                  First Name
                </label>
                <input
                  id="firstName"
                  name="firstName"
                  type="text"
                  required
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                    py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
                />
              </div>

              <div>
                <label
                  htmlFor="lastName"
                  className="block text-sm font-serif text-stone-700"
                >
                  Last Name
                </label>
                <input
                  id="lastName"
                  name="lastName"
                  type="text"
                  required
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                    py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
                />
              </div>
            </div>

            {/* Remaining form fields */}
            <div>
              <label
                htmlFor="username"
                className="block text-sm font-serif text-stone-700"
              >
                Username
              </label>
              <input
                id="username"
                name="username"
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                  py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
              />
            </div>

            <div>
              <label
                htmlFor="password"
                className="block text-sm font-serif text-stone-700"
              >
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                  py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
              />
            </div>

            <div>
              <label
                htmlFor="dateOfBirth"
                className="block text-sm font-serif text-stone-700"
              >
                Date of Birth
              </label>
              <input
                id="dateOfBirth"
                name="dateOfBirth"
                type="date"
                required
                value={dateOfBirth}
                onChange={(e) => setDateOfBirth(e.target.value)}
                className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                  py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
              />
            </div>

            <div className="grid grid-cols-2 gap-6">
              <div>
                <label
                  htmlFor="height"
                  className="block text-sm font-serif text-stone-700"
                >
                  Height (cm)
                </label>
                <input
                  id="height"
                  name="height"
                  type="number"
                  required
                  value={height}
                  onChange={(e) => setHeight(e.target.value)}
                  className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                    py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
                />
              </div>

              <div>
                <label
                  htmlFor="weight"
                  className="block text-sm font-serif text-stone-700"
                >
                  Weight (kg)
                </label>
                <input
                  id="weight"
                  name="weight"
                  type="number"
                  required
                  value={weight}
                  onChange={(e) => setWeight(e.target.value)}
                  className="mt-1 block w-full border border-stone-300 rounded-lg shadow-sm 
                    py-2 px-3 text-stone-800 focus:outline-none focus:ring-1 focus:ring-stone-500"
                />
              </div>
            </div>

            <div>
              <button
                type="submit"
                className="w-full flex justify-center py-2 px-4 border border-transparent 
                  rounded-lg shadow-sm text-white bg-stone-800 hover:bg-stone-700 
                  focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-stone-500
                  transition-colors"
              >
                Sign up
              </button>
            </div>
          </form>

          <div className="mt-6">
            <div className="relative">
              <div className="relative flex justify-center text-sm">
                <span className="px-2 text-stone-500">
                  Already have an account?{" "}
                  <Link
                    to="/login"
                    className="text-stone-800 hover:text-stone-700"
                  >
                    Log in
                  </Link>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
