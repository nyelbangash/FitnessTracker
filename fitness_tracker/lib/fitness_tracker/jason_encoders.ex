defmodule FitnessTracker.JasonEncoders do
  # For BSON.ObjectId
  defimpl Jason.Encoder, for: BSON.ObjectId do
    def encode(value, _opts) do
      "\"#{BSON.ObjectId.encode!(value)}\""
    end
  end

  # For Protocol.UndefinedError
  defimpl Jason.Encoder, for: Protocol.UndefinedError do
    def encode(value, _opts) do
      Jason.encode!(Map.from_struct(value))
    end
  end
end
