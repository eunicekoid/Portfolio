import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import Login from "../pages/Login";
import { vi } from "vitest";
/** @jsxImportSource react */

vi.stubGlobal("fetch", vi.fn());

describe("Login Component", () => {
  beforeEach(() => {
    fetch.mockClear();
  });

  test("should display login form", () => {
    render(<Login />);

    expect(screen.getByLabelText("Username")).toBeInTheDocument();
    expect(screen.getByLabelText("Password")).toBeInTheDocument();
    expect(screen.getByText("Login")).toBeInTheDocument();
  });

  test("should show error message for invalid login credentials", async () => {
    fetch.mockResolvedValueOnce({
      ok: false,
      json: async () => ({ error: "Invalid credentials" }),
    });

    render(<Login />);

    fireEvent.change(screen.getByLabelText("Username"), {
      target: { value: "wrongUser" },
    });
    fireEvent.change(screen.getByLabelText("Password"), {
      target: { value: "wrongPassword" },
    });

    fireEvent.click(screen.getByText("Login"));

    await waitFor(() =>
      expect(screen.getByText("Invalid credentials. No matching user found.")).toBeInTheDocument()
    );
  });

  test("should sign up and log in the user", async () => {
    fetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) }); // Signup
    fetch.mockResolvedValueOnce({ ok: true, json: async () => ({}) }); // Login

    render(<Login />);

    fireEvent.click(screen.getByText("Sign up here"));

    fireEvent.change(screen.getByLabelText("Username"), {
      target: { value: "newUser" },
    });
    fireEvent.change(screen.getByLabelText("Password"), {
      target: { value: "newPassword" },
    });

    fireEvent.click(screen.getByText("Sign Up"));

    await waitFor(() =>
      expect(screen.getByText("Signup successful! Logging in now...")).toBeInTheDocument()
    );
  });
});
