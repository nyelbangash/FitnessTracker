import { Input } from 'gym-bro-web';

export const Email = () => (
  <div style={{ width: 320 }}>
    <Input label="Email" type="email" defaultValue="alice@example.com" />
  </div>
);

export const WithHint = () => (
  <div style={{ width: 320 }}>
    <Input label="Password" type="password" hint="at least 12 characters" />
  </div>
);

export const WithError = () => (
  <div style={{ width: 320 }}>
    <Input label="Email" type="email" defaultValue="not an email" error="Doesn't look like an email" />
  </div>
);

export const Number = () => (
  <div style={{ width: 320 }}>
    <Input label="Weight (kg)" type="number" defaultValue="78" step={0.1} />
  </div>
);
