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
import { Delete as DeleteIcon, ArrowLeft } from "@mui/icons-material";
import { addMeal } from "../api";
import { useNavigate } from "react-router-dom";

const AddMeal = () => {
  const [mealName, setMealName] = useState("");
  const [ingredients, setIngredients] = useState([{ name: "" }]);
  const [date, setDate] = useState("");
  const [calories, setCalories] = useState("");
  const [protein, setProtein] = useState("");
  const [carbs, setCarbs] = useState("");
  const [fat, setFat] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // Validate required fields
      if (!mealName || !date || !calories || !protein || !carbs || !fat) {
        setError("Please fill in all required fields");
        return;
      }

      // Validate ingredients
      if (ingredients.some((ing) => !ing.name)) {
        setError("Please complete all ingredient fields");
        return;
      }

      const mealData = {
        mealName,
        ingredients,
        date,
        calories: parseInt(calories),
        protein: parseFloat(protein),
        carbs: parseFloat(carbs),
        fat: parseFloat(fat),
      };

      await addMeal(mealData);

      // Clear form and show success
      setMealName("");
      setIngredients([{ name: "" }]);
      setDate("");
      setCalories("");
      setProtein("");
      setCarbs("");
      setFat("");
      setSuccess("Meal added successfully!");
      setError("");

      // Clear success message after 3 seconds
      setTimeout(() => setSuccess(""), 3000);
    } catch (error) {
      setError("Failed to add meal. Please try again.");
    }
  };

  const handleIngredientChange = (index, value) => {
    const updatedIngredients = [...ingredients];
    updatedIngredients[index].name = value;
    setIngredients(updatedIngredients);
  };

  const addIngredient = () => {
    setIngredients([...ingredients, { name: "" }]);
  };

  const removeIngredient = (index) => {
    if (ingredients.length > 1) {
      const updatedIngredients = ingredients.filter((_, i) => i !== index);
      setIngredients(updatedIngredients);
    }
  };

  return (
    <Container maxWidth="md">
      <div className="mb-4 flex items-center">
        <button
          onClick={() => navigate("/")}
          className="flex items-center gap-2 text-blue-500"
        >
          <ArrowLeft size={20} />
          Back
        </button>
      </div>
      <Typography variant="h4" align="center" gutterBottom>
        Add Meal
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
              label="Meal Name"
              variant="outlined"
              fullWidth
              value={mealName}
              onChange={(e) => setMealName(e.target.value)}
            />
          </Grid>

          <Grid item xs={12}>
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
              label="Calories"
              variant="outlined"
              fullWidth
              type="number"
              value={calories}
              onChange={(e) => setCalories(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Protein (g)"
              variant="outlined"
              fullWidth
              type="number"
              value={protein}
              onChange={(e) => setProtein(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Carbs (g)"
              variant="outlined"
              fullWidth
              type="number"
              value={carbs}
              onChange={(e) => setCarbs(e.target.value)}
            />
          </Grid>

          <Grid item xs={12} sm={6}>
            <TextField
              label="Fat (g)"
              variant="outlined"
              fullWidth
              type="number"
              value={fat}
              onChange={(e) => setFat(e.target.value)}
            />
          </Grid>
        </Grid>

        <Typography variant="h6" sx={{ mt: 4, mb: 2 }}>
          Ingredients
        </Typography>

        {ingredients.map((ingredient, index) => (
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
              <Grid item xs={10}>
                <TextField
                  label="Ingredient Name"
                  variant="outlined"
                  fullWidth
                  value={ingredient.name}
                  onChange={(e) =>
                    handleIngredientChange(index, e.target.value)
                  }
                />
              </Grid>
              <Grid item xs={2}>
                <IconButton
                  onClick={() => removeIngredient(index)}
                  disabled={ingredients.length === 1}
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
          onClick={addIngredient}
          sx={{ mt: 2, mb: 4 }}
        >
          Add Ingredient
        </Button>

        <Button
          type="submit"
          variant="contained"
          color="primary"
          fullWidth
          size="large"
        >
          Save Meal
        </Button>
      </form>
    </Container>
  );
};

export default AddMeal;
