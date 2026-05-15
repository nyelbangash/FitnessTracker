import React, { useEffect, useRef, useState } from "react";
import { Send, X, Sparkles, ChevronDown, ChevronUp } from "lucide-react";
import * as api from "../api";

// Floating chat panel for refining a photo analysis. Lives in the bottom-right
// of the viewport while an analysis is active. The user types feedback ("no
// syrup", "the pancakes were smaller"); we re-run the AI and call onUpdate
// with the new analysis so the host page can refresh its form.
export const RefineChat = ({ analysisId, initialReply, onUpdate, onDismiss }) => {
  const [open, setOpen] = useState(true);
  const [messages, setMessages] = useState(() =>
    initialReply
      ? [{ role: "assistant", text: initialReply }]
      : [
          {
            role: "assistant",
            text:
              "I've drafted the meal. If anything's off — wrong portion, missing item, hidden oil — tell me and I'll redo it.",
          },
        ]
  );
  const [draft, setDraft] = useState("");
  const [sending, setSending] = useState(false);
  const scrollRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [open]);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, sending]);

  if (!analysisId) return null;

  const send = async () => {
    const text = draft.trim();
    if (!text || sending) return;

    const nextHistory = [...messages, { role: "user", text }];
    setMessages(nextHistory);
    setDraft("");
    setSending(true);

    try {
      // History sent to the server is everything BEFORE the new message;
      // refine_analysis/4 appends the user message internally.
      const result = await api.refineMealAnalysis(
        analysisId,
        text,
        messages.map((m) => ({ role: m.role, text: m.text }))
      );
      onUpdate(result);
      setMessages((prev) => [
        ...prev,
        { role: "assistant", text: result.reply || "Updated." },
      ]);
    } catch (err) {
      const detail =
        err?.response?.data?.error || err?.message || "Could not refine.";
      setMessages((prev) => [
        ...prev,
        { role: "assistant", text: `Error: ${detail}`, error: true },
      ]);
    } finally {
      setSending(false);
    }
  };

  return (
    <div
      className={`fixed z-40 rounded-lg shadow-lg animate-slide-up
        bottom-20 left-3 right-3 md:bottom-6 md:right-6 md:left-auto md:w-80`}
      style={{
        background: "var(--surface)",
        border: "1px solid var(--border)",
        boxShadow: "0 12px 32px rgba(0,0,0,0.18)",
        paddingBottom: "env(safe-area-inset-bottom, 0px)",
      }}
    >
      {/* Header */}
      <div
        className="flex items-center justify-between px-3 py-2 border-b"
        style={{ borderColor: "var(--border)" }}
      >
        <div className="flex items-center gap-2">
          <Sparkles size={14} style={{ color: "var(--accent)" }} />
          <span className="text-sm">Refine analysis</span>
        </div>
        <div className="flex items-center gap-1">
          <button
            onClick={() => setOpen((o) => !o)}
            className="text-muted hover:text-fg p-1"
            title={open ? "Collapse" : "Expand"}
          >
            {open ? <ChevronDown size={14} /> : <ChevronUp size={14} />}
          </button>
          <button
            onClick={onDismiss}
            className="text-muted hover:text-fg p-1"
            title="Dismiss"
          >
            <X size={14} />
          </button>
        </div>
      </div>

      {open && (
        <>
          <div
            ref={scrollRef}
            className="px-3 py-3 space-y-2 max-h-64 overflow-y-auto"
            style={{ minHeight: 100 }}
          >
            {messages.map((m, i) => (
              <div
                key={i}
                className={`text-sm flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className="px-2.5 py-1.5 rounded max-w-[85%]"
                  style={{
                    background:
                      m.role === "user"
                        ? "var(--accent)"
                        : m.error
                        ? "var(--surface-2)"
                        : "var(--surface-2)",
                    color:
                      m.role === "user"
                        ? "var(--accent-text)"
                        : m.error
                        ? "var(--bad)"
                        : "var(--text)",
                  }}
                >
                  {m.text}
                </div>
              </div>
            ))}
            {sending && (
              <div className="text-sm flex justify-start">
                <div
                  className="px-2.5 py-1.5 rounded text-muted italic"
                  style={{ background: "var(--surface-2)" }}
                >
                  Thinking…
                </div>
              </div>
            )}
          </div>

          <div
            className="flex items-end gap-2 px-2 py-2 border-t"
            style={{ borderColor: "var(--border)" }}
          >
            <textarea
              ref={inputRef}
              rows={1}
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  send();
                }
              }}
              placeholder="Tell me what's off…"
              className="flex-1 px-2.5 py-1.5 text-sm rounded outline-none resize-none"
              style={{
                background: "var(--bg)",
                color: "var(--text)",
                border: "1px solid var(--border)",
                maxHeight: 100,
              }}
              disabled={sending}
            />
            <button
              onClick={send}
              disabled={sending || !draft.trim()}
              className="p-1.5 rounded disabled:opacity-40"
              style={{
                background: "var(--accent)",
                color: "var(--accent-text)",
              }}
              title="Send (Enter)"
            >
              <Send size={14} />
            </button>
          </div>
        </>
      )}
    </div>
  );
};
