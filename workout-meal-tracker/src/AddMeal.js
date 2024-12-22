// AddMeal.js
import React, { useState } from "react";
import {
  TextField,
  Button,
  Container,
  Typography,
  Grid,
  IconButton,
} from "@mui/material";
import { Delete as DeleteIcon } from "@mui/icons-material";
import { addMeal } from "./api";

const AddMeal = () => {
  const [mealName, setMealName] = useState("");
  const [ingredients, setIngredients] = useState([{ name: "", amount: "" }]);
  const [date, setDate] = useState("");
  const [calories, setCalories] = useState("");
  const [protein, setProtein] = useState("");
  const [carbs, setCarbs] = useState("");
  const [fat, setFat] = useState("");

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const mealData = {
        mealName,
        ingredients,
        date,
        calories,
        protein,
        carbs,
        fat,
      };
      await addMeal(mealData);
      // Clear form fields after successful submission
      setMealName("");
      setIngredients([{ name: "", amount: "" }]);
      setDate("");
      setCalories("");
      setProtein("");
      setCarbs("");
      setFat("");
      // Display success message or update meal log
    } catch (error) {
      // Handle error, e.g., display error message
    }
  };

  const handleIngredientChange = (index, field, value) => {
    const updatedIngredients = [...ingredients];
    updatedIngredients[index][field] = value;
    setIngredients(updatedIngredients);
  };

  const addIngredient = () => {
    setIngredients([...ingredients, { name: "", amount: "" }]);
  };

  const removeIngredient = (index) => {
    const updatedIngredients = ingredients.filter((_, i) => i !== index);
    setIngredients(updatedIngredients);
  };

  return (
    <Container maxWidth="sm">
      <Typography variant="h4" align="center" gutterBottom>
        Add Meal
      </Typography>
      <form onSubmit={handleSubmit}>
        <TextField
          label="Meal Name"
          variant="outlined"
          fullWidth
          margin="normal"
          value={mealName}
          onChange={(e) => setMealName(e.target.value)}
        />
        <TextField
          label="Date"
          variant="outlined"
          fullWidth
          margin="normal"
          value={date}
          onChange={(e) => setDate(e.target.value)}
        />
        <TextField
          label="Calories"
          variant="outlined"
          fullWidth
          margin="normal"
          value={calories}
          onChange={(e) => setCalories(e.target.value)}
        />
        <TextField
          label="Protein"
          variant="outlined"
          fullWidth
          margin="normal"
          value={protein}
          onChange={(e) => setProtein(e.target.value)}
        />
        <TextField
          label="Carbs"
          variant="outlined"
          fullWidth
          margin="normal"
          value={carbs}
          onChange={(e) => setCarbs(e.target.value)}
        />
        <TextField
          label="Fat"
          variant="outlined"
          fullWidth
          margin="normal"
          value={fat}
          onChange={(e) => setFat(e.target.value)}
        />
        {ingredients.map((ingredient, index) => (
          <Grid container key={index} spacing={2} alignItems="center">
            <Grid item xs={6}>
              <TextField
                label="Ingredient Name"
                variant="outlined"
                fullWidth
                value={ingredient.name}
                onChange={(e) =>
                  handleIngredientChange(index, "name", e.target.value)
                }
              />
            </Grid>
            <Grid item xs={4}>
              <TextField
                label="Amount"
                variant="outlined"
                fullWidth
                value={ingredient.amount}
                onChange={(e) =>
                  handleIngredientChange(index, "amount", e.target.value)
                }
              />
            </Grid>
            <Grid item xs={2}>
              <IconButton onClick={() => removeIngredient(index)}>
                <DeleteIcon />
              </IconButton>
            </Grid>
          </Grid>
        ))}
        <Button variant="outlined" color="primary" onClick={addIngredient}>
          Add Ingredient
        </Button>
        <Button
          type="submit"
          variant="contained"
          color="primary"
          fullWidth
          style={{ marginTop: "16px" }}
        >
          Add Meal
        </Button>
      </form>
    </Container>
  );
};

export default AddMeal;
