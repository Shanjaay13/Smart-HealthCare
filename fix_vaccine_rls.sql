-- Fix RLS policies for vaccine_records to allow users to insert, update, and delete their own records.

-- Allow users to insert their own records
CREATE POLICY "Users can insert own vaccine records" 
ON public.vaccine_records FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own records
CREATE POLICY "Users can update own vaccine records" 
ON public.vaccine_records FOR UPDATE 
USING (auth.uid() = user_id);

-- Allow users to delete their own records
CREATE POLICY "Users can delete own vaccine records" 
ON public.vaccine_records FOR DELETE 
USING (auth.uid() = user_id);
