import React, { useState } from "react";
import {
  TextField,
  Button,
  Container,
  Typography,
  IconButton,
  Alert,
  Box,
  Grid,
} from "@mui/material";
import { Delete as DeleteIcon } from "@mui/icons-material";
import { addWorkout } from "../api";

const AddWorkout = () => {
  const [workoutName, setWorkoutName] = useState("");
  const [exercises, setExercises] = useState([
    { name: "", sets: "", reps: "", weight: "" },
  ]);
  const [date, setDate] = useState("");
  const [duration, setDuration] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Validate required fields
      if (!workoutName || !date || !duration) {
        setError("Please fill in all required fields");
        return;
      }

      // Validate exercises
      if (
        exercises.some((ex) => !ex.name || !ex.sets || !ex.reps || !ex.weight)
      ) {
        setError("Please complete all exercise fields");
        return;
      }

      const workoutData = {
        workoutName,
        exercises: exercises.map((exercise) => ({
          name: exercise.name,
          sets: [
            {
              reps: parseInt(exercise.reps),
              weight: parseFloat(exercise.weight),
            },
          ],
        })),
        date,
        duration,
      };

      await addWorkout(workoutData);

      // Clear form and show success
      setWorkoutName("");
      setExercises([{ name: "", sets: "", reps: "", weight: "" }]);
      setDate("");
      setDuration("");
      setSuccess("Workout added successfully!");
      setError("");

      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(""), 3000);
    } catch (error) {
      setError("Failed to add workout. Please try again.");
    }
  };

  const handleExerciseChange = (index, field, value) => {
    const updatedExercises = [...exercises];
    updatedExercises[index][field] = value;
    setExercises(updatedExercises);
  };

  const addExercise = () => {
    setExercises([...exercises, { name: "", sets: "", reps: "", weight: "" }]);
  };

  const removeExercise = (index) => {
    if (exercises.length > 1) {
      const updatedExercises = exercises.filter((_, i) => i !== index);
      setExercises(updatedExercises);
    }
  };

  return (
    <Container maxWidth="md">
      <Typography variant="h4" align="center" gutterBottom>
        Add Workout
      </Typography>

      {error && (
        <Alert severity="error" onClose={() => setError("")} sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {success && (
        <Alert severity="success" onClose={() => setSuccess("")} sx={{ mb: 2 }}>
          {success}
        </Alert>
      )}

      <form onSubmit={handleSubmit}>
        <Grid container spacing={2}>
          <Grid item xs={12}>
            <TextField
              label="Workout Name"
              variant="outlined"
              fullWidth
              value={workoutName}
              onChange={(e) => setWorkoutName(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Date"
              type="date"
              variant="outlined"
              fullWidth
              value={date}
              onChange={(e) => setDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Duration (minutes)"
              variant="outlined"
              fullWidth
              type="number"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
            />
          </Grid>
        </Grid>

        <Typography variant="h6" sx={{ mt: 4, mb: 2 }}>
          Exercises
        </Typography>

        {exercises.map((exercise, index) => (
          <Box
            key={index}
            sx={{
              mb: 2,
              p: 2,
              border: 1,
              borderColor: "grey.300",
              borderRadius: 1,
            }}
          >
            <Grid container spacing={2} alignItems="center">
              <Grid item xs={12} sm={3}>
                <TextField
                  label="Exercise Name"
                  variant="outlined"
                  fullWidth
                  value={exercise.name}
                  onChange={(e) =>
                    handleExerciseChange(index, "name", e.target.value)
                  }
                />
              </Grid>
              <Grid item xs={12} sm={2}>
                <TextField
                  label="Sets"
                  variant="outlined"
                  fullWidth
                  type="number"
                  value={exercise.sets}
                  onChange={(e) =>
                    handleExerciseChange(index, "sets", e.target.value)
                  }
                />
              </Grid>
              <Grid item xs={12} sm={2}>
                <TextField
                  label="Reps"
                  variant="outlined"
                  fullWidth
                  type="number"
                  value={exercise.reps}
                  onChange={(e) =>
                    handleExerciseChange(index, "reps", e.target.value)
                  }
                />
              </Grid>
              <Grid item xs={12} sm={2}>
                <TextField
                  label="Weight (kg)"
                  variant="outlined"
                  fullWidth
                  type="number"
                  value={exercise.weight}
                  onChange={(e) =>
                    handleExerciseChange(index, "weight", e.target.value)
                  }
                />
              </Grid>
              <Grid item xs={12} sm={2}>
                <IconButton
                  onClick={() => removeExercise(index)}
                  disabled={exercises.length === 1}
                >
                  <DeleteIcon />
                </IconButton>
              </Grid>
            </Grid>
          </Box>
        ))}

        <Button
          variant="outlined"
          color="primary"
          onClick={addExercise}
          sx={{ mt: 2, mb: 4 }}
        >
          Add Exercise
        </Button>

        <Button
          type="submit"
          variant="contained"
          color="primary"
          fullWidth
          size="large"
        >
          Save Workout
        </Button>
      </form>
    </Container>
  );
};

export default AddWorkout;
