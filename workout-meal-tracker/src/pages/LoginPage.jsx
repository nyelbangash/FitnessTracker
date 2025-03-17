import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { Dumbbell } from "lucide-react";

export const LoginPage = () => {
  const [username, setUsername] = useState("");
  const { login } = useAuth(); // Make sure login is destructured from the context
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await login(username, password);
      navigate("/");
    } catch (error) {
      setError("Invalid username or password");
    }
  };

  return (
    <div className="min-h-screen bg-stone-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <Dumbbell className="mx-auto h-12 w-12 text-stone-800" />
        <h2 className="mt-6 text-center text-3xl font-serif text-stone-800">
          Sign in to FitnessTracker
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
              <button
                type="submit"
                className="w-full flex justify-center py-2 px-4 border border-transparent 
                  rounded-lg shadow-sm text-white bg-stone-800 hover:bg-stone-700 
                  focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-stone-500
                  transition-colors"
              >
                Sign in
              </button>
            </div>
          </form>

          <div className="mt-6">
            <div className="relative">
              <div className="relative flex justify-center text-sm">
                <span className="px-2 text-stone-500">
                  Don't have an account?{" "}
                  <Link
                    to="/signup"
                    className="text-stone-800 hover:text-stone-700"
                  >
                    Sign up
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
