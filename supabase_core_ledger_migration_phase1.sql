-- =================================================================================
-- ASTRACK — PHASE 1 CORE LEDGER & ATOMIC TRANSACTIONS MIGRATION
-- Safe & Idempotent Migration for Supabase PostgreSQL
-- =================================================================================

-- 1. Ensure Columns Exist for Phase 1 Core Ledger
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_user_idempotency 
    ON public.transactions(user_id, idempotency_key) 
    WHERE idempotency_key IS NOT NULL;

ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT false;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;
ALTER TABLE public.fund_sources ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

-- 2. Seed Default Indonesian Categories if not already present
INSERT INTO public.categories (id, user_id, name, icon_name, color_hex, type, is_default, is_archived, created_at, updated_at)
VALUES 
    ('cat_food', NULL, 'Food & Beverage', 'utensils', 'EF4444', 'expense', true, false, now(), now()),
    ('cat_coffee', NULL, 'Coffee', 'coffee', 'F59E0B', 'expense', true, false, now(), now()),
    ('cat_transport', NULL, 'Transportation', 'car', '3B82F6', 'expense', true, false, now(), now()),
    ('cat_shopping', NULL, 'Shopping', 'shopping_bag', 'EC4899', 'expense', true, false, now(), now()),
    ('cat_bills', NULL, 'Bills & Utilities', 'receipt', '8B5CF6', 'expense', true, false, now(), now()),
    ('cat_entertainment', NULL, 'Entertainment', 'film', '6366F1', 'expense', true, false, now(), now()),
    ('cat_salary', NULL, 'Salary & Freelance', 'briefcase', '16A34A', 'income', true, false, now(), now()),
    ('cat_gift', NULL, 'Uang dari Orang Tua', 'gift', '10B981', 'income', true, false, now(), now()),
    ('cat_other', NULL, 'Others', 'more_horizontal', '64748B', 'expense', true, false, now(), now())
ON CONFLICT (id) DO UPDATE SET
    is_default = true,
    name = EXCLUDED.name;

-- 3. Atomic Transaction Mutation RPC (ACID Compliant)
CREATE OR REPLACE FUNCTION public.create_ledger_transaction(
    p_id TEXT,
    p_type TEXT,
    p_amount NUMERIC,
    p_description TEXT,
    p_category_id TEXT,
    p_category_name TEXT,
    p_source_id TEXT,
    p_source_name TEXT,
    p_target_source_id TEXT DEFAULT NULL,
    p_target_source_name TEXT DEFAULT NULL,
    p_savings_goal_id TEXT DEFAULT NULL,
    p_date_time TIMESTAMPTZ DEFAULT now(),
    p_notes TEXT DEFAULT '',
    p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_existing_id TEXT;
    v_result JSONB;
    v_month INT;
    v_year INT;
BEGIN
    -- Auth check
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna belum terautentikasi.';
    END IF;

    -- Amount check
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Nominal transaksi harus lebih besar dari 0.';
    END IF;

    -- Idempotency protection check
    IF p_idempotency_key IS NOT NULL THEN
        SELECT id INTO v_existing_id
        FROM public.transactions
        WHERE user_id = v_user_id AND idempotency_key = p_idempotency_key;

        IF v_existing_id IS NOT NULL THEN
            SELECT jsonb_build_object(
                'status', 'idempotent_duplicate',
                'transaction_id', id,
                'message', 'Transaksi sudah tercatat sebelumnya.'
            ) INTO v_result
            FROM public.transactions
            WHERE id = v_existing_id;
            
            RETURN v_result;
        END IF;
    END IF;

    -- 1. Insert Transaction Item
    INSERT INTO public.transactions (
        id,
        user_id,
        type,
        amount,
        description,
        category_id,
        category_name,
        source_id,
        source_name,
        target_source_id,
        target_source_name,
        savings_goal_id,
        date_time,
        notes,
        idempotency_key,
        sync_status,
        created_at,
        updated_at
    ) VALUES (
        p_id,
        v_user_id,
        p_type,
        p_amount,
        p_description,
        p_category_id,
        p_category_name,
        p_source_id,
        p_source_name,
        p_target_source_id,
        p_target_source_name,
        p_savings_goal_id,
        p_date_time,
        p_notes,
        p_idempotency_key,
        'synced',
        now(),
        now()
    );

    -- 2. Atomic Balance Updates on Fund Sources
    IF p_type = 'income' THEN
        UPDATE public.fund_sources
        SET balance = balance + p_amount, updated_at = now()
        WHERE id = p_source_id AND user_id = v_user_id;

    ELSIF p_type = 'expense' THEN
        UPDATE public.fund_sources
        SET balance = balance - p_amount, updated_at = now()
        WHERE id = p_source_id AND user_id = v_user_id;

        -- Update monthly budget if active
        v_month := EXTRACT(MONTH FROM p_date_time);
        v_year := EXTRACT(YEAR FROM p_date_time);
        UPDATE public.budgets
        SET spent_amount = spent_amount + p_amount, updated_at = now()
        WHERE user_id = v_user_id AND category_id = p_category_id AND month = v_month AND year = v_year;

    ELSIF p_type = 'transfer' THEN
        UPDATE public.fund_sources
        SET balance = balance - p_amount, updated_at = now()
        WHERE id = p_source_id AND user_id = v_user_id;

        IF p_target_source_id IS NOT NULL THEN
            UPDATE public.fund_sources
            SET balance = balance + p_amount, updated_at = now()
            WHERE id = p_target_source_id AND user_id = v_user_id;
        END IF;

    ELSIF p_type = 'saving' THEN
        UPDATE public.fund_sources
        SET balance = balance - p_amount, updated_at = now()
        WHERE id = p_source_id AND user_id = v_user_id;

        IF p_target_source_id IS NOT NULL THEN
            UPDATE public.fund_sources
            SET balance = balance + p_amount, updated_at = now()
            WHERE id = p_target_source_id AND user_id = v_user_id;
        END IF;

        IF p_savings_goal_id IS NOT NULL THEN
            UPDATE public.savings_goals
            SET current_amount = current_amount + p_amount, updated_at = now()
            WHERE id = p_savings_goal_id AND user_id = v_user_id;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'status', 'success',
        'transaction_id', p_id,
        'type', p_type,
        'amount', p_amount,
        'idempotency_key', p_idempotency_key
    );
END;
$$;

-- 4. Atomic Transaction Deletion / Reversal RPC
CREATE OR REPLACE FUNCTION public.delete_ledger_transaction(
    p_transaction_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_tx RECORD;
    v_month INT;
    v_year INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna belum terautentikasi.';
    END IF;

    SELECT * INTO v_tx
    FROM public.transactions
    WHERE id = p_transaction_id AND user_id = v_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'not_found', 'transaction_id', p_transaction_id);
    END IF;

    -- Reverse balance mutations
    IF v_tx.type = 'income' THEN
        UPDATE public.fund_sources
        SET balance = balance - v_tx.amount, updated_at = now()
        WHERE id = v_tx.source_id AND user_id = v_user_id;

    ELSIF v_tx.type = 'expense' THEN
        UPDATE public.fund_sources
        SET balance = balance + v_tx.amount, updated_at = now()
        WHERE id = v_tx.source_id AND user_id = v_user_id;

        v_month := EXTRACT(MONTH FROM v_tx.date_time);
        v_year := EXTRACT(YEAR FROM v_tx.date_time);
        UPDATE public.budgets
        SET spent_amount = GREATEST(0, spent_amount - v_tx.amount), updated_at = now()
        WHERE user_id = v_user_id AND category_id = v_tx.category_id AND month = v_month AND year = v_year;

    ELSIF v_tx.type = 'transfer' OR v_tx.type = 'saving' THEN
        UPDATE public.fund_sources
        SET balance = balance + v_tx.amount, updated_at = now()
        WHERE id = v_tx.source_id AND user_id = v_user_id;

        IF v_tx.target_source_id IS NOT NULL THEN
            UPDATE public.fund_sources
            SET balance = balance - v_tx.amount, updated_at = now()
            WHERE id = v_tx.target_source_id AND user_id = v_user_id;
        END IF;

        IF v_tx.savings_goal_id IS NOT NULL THEN
            UPDATE public.savings_goals
            SET current_amount = GREATEST(0, current_amount - v_tx.amount), updated_at = now()
            WHERE id = v_tx.savings_goal_id AND user_id = v_user_id;
        END IF;
    END IF;

    -- Delete transaction record
    DELETE FROM public.transactions WHERE id = p_transaction_id AND user_id = v_user_id;

    RETURN jsonb_build_object('status', 'success', 'transaction_id', p_transaction_id);
END;
$$;
