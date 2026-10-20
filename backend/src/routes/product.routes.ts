import { Router } from "express";
import pool from "../config/database";

const router = Router();

router.get("/", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, description, category, base_price AS price FROM products WHERE available = TRUE ORDER BY id"
    );

    res.json(result.rows);
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Error obteniendo los productos"
    });
  }
});

export default router;
