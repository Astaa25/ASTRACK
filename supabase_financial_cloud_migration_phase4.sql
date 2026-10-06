-- =================================================================================
-- ASTRACK — PHASE 4 FINANCIAL CLOUD TABLES & ROW LEVEL SECURITY (SAFE MIGRATION)
-- Non-destructive: Uses CREATE TABLE IF NOT EXISTS and CREATE INDEX IF NOT EXISTS
-- =================================================================================

-- 1. FUND SOURCES
CREATE TABLE IF NOT EXISTS public.fund_sources (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    balance NUMERIC DEFAULT 0 NOT NULL,
    icon_name TEXT DEFAULT 'wallet',
    color_hex TEXT DEFAULT '087F5B',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sources_user ON public.fund_sources(user_id);

ALTER TABLE public.fund_sources ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fund_sources' AND policyname = 'Users can view own fund sources') THEN
        CREATE POLICY "Users can view own fund sources" ON public.fund_sources FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fund_sources' AND policyname = 'Users can insert own fund sources') THEN
        CREATE POLICY "Users can insert own fund sources" ON public.fund_sources FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fund_sources' AND policyname = 'Users can update own fund sources') THEN
        CREATE POLICY "Users can update own fund sources" ON public.fund_sources FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fund_sources' AND policyname = 'Users can delete own fund sources') THEN
        CREATE POLICY "Users can delete own fund sources" ON public.fund_sources FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 2. CATEGORIES
CREATE TABLE IF NOT EXISTS public.categories (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon_name TEXT DEFAULT 'category',
    color_hex TEXT DEFAULT '4F46E5',
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'categories' AND policyname = 'Users can view own or default categories') THEN
        CREATE POLICY "Users can view own or default categories" ON public.categories FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL OR is_default = true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'categories' AND policyname = 'Users can insert own categories') THEN
        CREATE POLICY "Users can insert own categories" ON public.categories FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'categories' AND policyname = 'Users can update own categories') THEN
        CREATE POLICY "Users can update own categories" ON public.categories FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'categories' AND policyname = 'Users can delete own categories') THEN
        CREATE POLICY "Users can delete own categories" ON public.categories FOR DELETE USING (auth.uid() = user_id AND is_default = false);
    END IF;
END $$;

-- 3. TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.transactions (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer', 'saving')),
    amount NUMERIC NOT NULL,
    description TEXT NOT NULL,
    category_id TEXT NOT NULL,
    category_name TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_name TEXT NOT NULL,
    target_source_id TEXT,
    target_source_name TEXT,
    savings_goal_id TEXT,
    recurring_id TEXT,
    date_time TIMESTAMPTZ NOT NULL,
    notes TEXT,
    sync_status TEXT DEFAULT 'synced',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_datetime ON public.transactions(user_id, date_time);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'transactions' AND policyname = 'Users can view own transactions') THEN
        CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'transactions' AND policyname = 'Users can insert own transactions') THEN
        CREATE POLICY "Users can insert own transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'transactions' AND policyname = 'Users can update own transactions') THEN
        CREATE POLICY "Users can update own transactions" ON public.transactions FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'transactions' AND policyname = 'Users can delete own transactions') THEN
        CREATE POLICY "Users can delete own transactions" ON public.transactions FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 4. BUDGETS
CREATE TABLE IF NOT EXISTS public.budgets (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    category_id TEXT NOT NULL,
    category_name TEXT NOT NULL,
    limit_amount NUMERIC NOT NULL,
    spent_amount NUMERIC DEFAULT 0 NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_period ON public.budgets(user_id, year, month);

ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'budgets' AND policyname = 'Users can view own budgets') THEN
        CREATE POLICY "Users can view own budgets" ON public.budgets FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'budgets' AND policyname = 'Users can insert own budgets') THEN
        CREATE POLICY "Users can insert own budgets" ON public.budgets FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'budgets' AND policyname = 'Users can update own budgets') THEN
        CREATE POLICY "Users can update own budgets" ON public.budgets FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'budgets' AND policyname = 'Users can delete own budgets') THEN
        CREATE POLICY "Users can delete own budgets" ON public.budgets FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 5. SAVINGS GOALS
CREATE TABLE IF NOT EXISTS public.savings_goals (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    target_amount NUMERIC NOT NULL,
    current_amount NUMERIC DEFAULT 0 NOT NULL,
    target_date TIMESTAMPTZ NOT NULL,
    color_hex TEXT DEFAULT '10B981',
    icon_name TEXT DEFAULT 'savings',
    source_id TEXT,
    source_name TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_savings_user ON public.savings_goals(user_id);

ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'savings_goals' AND policyname = 'Users can view own savings goals') THEN
        CREATE POLICY "Users can view own savings goals" ON public.savings_goals FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'savings_goals' AND policyname = 'Users can insert own savings goals') THEN
        CREATE POLICY "Users can insert own savings goals" ON public.savings_goals FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'savings_goals' AND policyname = 'Users can update own savings goals') THEN
        CREATE POLICY "Users can update own savings goals" ON public.savings_goals FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'savings_goals' AND policyname = 'Users can delete own savings goals') THEN
        CREATE POLICY "Users can delete own savings goals" ON public.savings_goals FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 6. RECURRING TRANSACTIONS
CREATE TABLE IF NOT EXISTS public.recurring_transactions (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    amount NUMERIC NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
    category_id TEXT NOT NULL,
    category_name TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_name TEXT NOT NULL,
    frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
    start_date TIMESTAMPTZ NOT NULL,
    next_occurrence TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_recurring_user ON public.recurring_transactions(user_id);

ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recurring_transactions' AND policyname = 'Users can view own recurring') THEN
        CREATE POLICY "Users can view own recurring" ON public.recurring_transactions FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recurring_transactions' AND policyname = 'Users can insert own recurring') THEN
        CREATE POLICY "Users can insert own recurring" ON public.recurring_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recurring_transactions' AND policyname = 'Users can update own recurring') THEN
        CREATE POLICY "Users can update own recurring" ON public.recurring_transactions FOR UPDATE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'recurring_transactions' AND policyname = 'Users can delete own recurring') THEN
        CREATE POLICY "Users can delete own recurring" ON public.recurring_transactions FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;
