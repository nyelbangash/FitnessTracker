export const formatDate = (date) => {
  return new Date(date).toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  });
};

export const formatTime = (seconds) => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
};

export const calculateTotalVolume = (exercises) => {
  return exercises.reduce((total, exercise) => {
    return (
      total +
      exercise.sets.reduce((setTotal, set) => {
        return setTotal + set.reps * set.weight;
      }, 0)
    );
  }, 0);
};

export const calculateAverageRPE = (exercises) => {
  let totalRPE = 0;
  let totalSets = 0;

  exercises.forEach((exercise) => {
    exercise.sets.forEach((set) => {
      if (set.rpe) {
        totalRPE += set.rpe;
        totalSets++;
      }
    });
  });

  return totalSets > 0 ? totalRPE / totalSets : 0;
};
