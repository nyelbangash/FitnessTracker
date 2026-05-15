import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { Button, Input, Card, CardBody } from "../ui";

export const SignupPage = () => {
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [dateOfBirth, setDateOfBirth] = useState("");
  const [height, setHeight] = useState("");
  const [weight, setWeight] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const { signup } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      await signup({
        firstName,
        lastName,
        email,
        password,
        dateOfBirth,
        height: height ? parseFloat(height) : null,
        weight: weight ? parseFloat(weight) : null,
      });
      navigate("/");
    } catch (err) {
      const detail = err?.response?.data?.errors;
      if (detail) {
        const first = Object.entries(detail)[0];
        setError(`${first[0]}: ${first[1].join(", ")}`);
      } else {
        setError("Failed to create account");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-bg px-4 py-8">
      <div className="w-full max-w-md space-y-6 animate-fade-in">
        <div className="text-center">
          <div className="font-serif-h text-3xl">Gym Bro</div>
          <div className="text-muted text-sm mt-1">Create your account</div>
        </div>
        <Card>
          <CardBody>
            <form className="space-y-4" onSubmit={handleSubmit}>
              {error && <div className="text-sm text-bad">{error}</div>}
              <div className="grid grid-cols-2 gap-3">
                <Input
                  label="First name"
                  required
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                />
                <Input
                  label="Last name"
                  required
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                />
              </div>
              <Input
                label="Email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <Input
                label="Password"
                type="password"
                autoComplete="new-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                hint="at least 12 characters"
              />
              <Input
                label="Date of birth"
                type="date"
                value={dateOfBirth}
                onChange={(e) => setDateOfBirth(e.target.value)}
              />
              <div className="grid grid-cols-2 gap-3">
                <Input
                  label="Height (cm)"
                  type="number"
                  value={height}
                  onChange={(e) => setHeight(e.target.value)}
                />
                <Input
                  label="Weight (kg)"
                  type="number"
                  step="0.1"
                  value={weight}
                  onChange={(e) => setWeight(e.target.value)}
                />
              </div>
              <Button
                variant="primary"
                type="submit"
                full
                size="lg"
                disabled={submitting}
              >
                {submitting ? "Creating account…" : "Create account"}
              </Button>
            </form>
          </CardBody>
        </Card>
        <div className="text-center text-sm text-muted">
          Already have an account?{" "}
          <Link to="/login" className="text-fg hover:underline">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  );
};
