-- Add missing UPDATE policy
CREATE POLICY "Users can update own appointments" 
ON public.appointments FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Add missing DELETE policy
CREATE POLICY "Users can delete own appointments" 
ON public.appointments FOR DELETE
USING (auth.uid() = user_id);
