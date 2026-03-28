ALTER TABLE packs ADD COLUMN wavetable_id uuid REFERENCES wavetables(id);
