# Guia de Configuração do Banco de Dados no Supabase

Este guia ajuda você a criar o seu projeto, configurar a autenticação e preparar o banco de dados (tabelas e colunas) no console do Supabase para que o seu aplicativo **Taskfy** funcione sem problemas online.

---

## 1. Criando e Configurando o Projeto
1. Acesse: [https://supabase.com/dashboard](https://supabase.com/dashboard) e entre na sua conta (ou crie uma gratuitamente).
2. Clique no botão **"New Project"**.
3. Escolha um nome ("Taskfy"), selecione a região (ex: "South America - São Paulo") e crie uma senha forte pro Banco de Dados.
4. Aguarde de 1 a 2 minutos até que o projeto seja completamente originado.

Logo na página inicial do projeto, no lado inferior ou na seção "Project Settings" > "API", você achará a **Project URL** e a **anon / public key**. Cole elas no nosso arquivo `lib/services/supabase_config.dart`.

---

## 2. Preparando as Tabelas SQL
O Supabase usa PostgreSQL. Para criarmos as tabelas facilmente com todos os parâmetros que nós designamos via código no Dart, você pode apenas **abrir a aba "SQL Editor"** (menu lateral da esquerda) e clicar em **"New query"**.

> Cole o código SQL abaixo inteiramente dentro do editor e aperte em **Run**:

```sql
-- 1. Criação da Tabela de Perfis (`profiles`)
-- (Registra o nome e email do usuário no login)
CREATE TABLE public.profiles (
  id uuid NOT NULL REFERENCES auth.users on delete cascade,
  name text,
  email text,
  PRIMARY KEY (id)
);

-- 2. Criação da Tabela de Tarefas (`tasks`)
-- (Registra a modelagem dos afazeres contendo listas de histórico/checklist em formato JSON)
CREATE TABLE public.tasks (
  "id" text NOT NULL,
  "title" text NOT NULL,
  "description" text,
  "dueDate" timestamptz NOT NULL,
  "priority" text DEFAULT 'Média'::text,
  "status" text DEFAULT 'Pendente'::text,
  "category" text DEFAULT 'Sem Categoria'::text,
  "createdAt" timestamptz DEFAULT now(),
  "updatedAt" timestamptz DEFAULT now(),
  "hasAlarm" boolean DEFAULT false,
  "recurrence" text DEFAULT 'S/ Repetição'::text,
  "createdBy" text,
  
  -- Essas colunas como JSONB servem para guardar listas complexas/arrays com segurança --
  "assignedTo" jsonb DEFAULT '[]'::jsonb,
  "sharedWith" jsonb DEFAULT '[]'::jsonb,
  "checklist" jsonb DEFAULT '[]'::jsonb,
  "history" jsonb DEFAULT '[]'::jsonb,
  
  PRIMARY KEY ("id")
);

-- 3. Regras e Políticas (RLS - Permissões Básicas)
-- Atenção: Ativa a permissão de leitura, criação e atualização por todo mundo (Para fins de testes fáceis e garantir o acesso simultâneo).
-- Num app 100% de produção, configuram-se políticas rígidas de "só o Admin gerencia tudo" aqui depois.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pass-all Profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Pass-all Tasks" ON public.tasks FOR ALL USING (true) WITH CHECK (true);
```

### O que esse script faz?
Ele cria a tabela `profiles` na qual o seu serviço de Login salva o prenome, e também cria a tabela `tasks` principal com as colunas que adicionamos mais cedo (Histórico, Usuário Designado, Compartilhamento e Status). Como os Sub-itens do Dart são passados em formato "List", definimos "JSONB" que se adapta automaticamente a essas listas de Mapas que enviamos no Flutter!

---

## 3. Rodando o Aplicativo
Com o Query rodado em sucesso através de "Run" e com as suas URL/KEY preenchidas corretamente no `supabase_config.dart`, ligue o compilador e teste o fluxo criando a sua primeira conta no painel de Registro do app! O Dashboard de Authentication do Supabase logo gravará o primeiro email logado.
