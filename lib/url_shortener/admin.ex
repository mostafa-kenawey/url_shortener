defmodule UrlShortener.Admin do
  import Ecto.Query, warn: false
  alias UrlShortener.Repo
  alias UrlShortener.Admin.{Account, AdminToken, AdminNotifier, Link}

  # Link functions
  def list_links, do: Repo.all(Link)
  def get_link!(id), do: Repo.get!(Link, id)
  def create_link(attrs \\ %{}), do: %Link{} |> Link.changeset(attrs) |> Repo.insert()
  def update_link(%Link{} = link, attrs), do: link |> Link.changeset(attrs) |> Repo.update()
  def delete_link(%Link{} = link), do: Repo.delete(link)
  def change_link(%Link{} = link, attrs \\ %{}), do: Link.changeset(link, attrs)

  # Admin account functions
  def get_admin_by_email(email) when is_binary(email), do: Repo.get_by(Account, email: email)
  def get_admin!(id), do: Repo.get!(Account, id)
  def register_admin(attrs), do: %Account{} |> Account.registration_changeset(attrs) |> Repo.insert()

  def get_admin_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    admin = Repo.get_by(Account, email: email)
    if Account.valid_password?(admin, password), do: admin
  end

  def change_admin_registration(%Account{} = admin, attrs \\ %{}) do
    Account.registration_changeset(admin, attrs, hash_password: false, validate_email: false)
  end

  def change_admin_email(admin, attrs \\ %{}), do: Account.email_changeset(admin, attrs, validate_email: false)

  def apply_admin_email(admin, password, attrs) do
    admin |> Account.email_changeset(attrs) |> Account.validate_current_password(password) |> Ecto.Changeset.apply_action(:update)
  end

  def update_admin_email(admin, token) do
    context = "change:#{admin.email}"

    with {:ok, query} <- AdminToken.verify_change_email_token_query(token, context),
         %AdminToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(admin_email_multi(admin, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp admin_email_multi(admin, email, context) do
    changeset =
      admin
      |> Account.email_changeset(%{email: email})
      |> Account.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, [context]))
  end

  def deliver_admin_update_email_instructions(%Account{} = admin, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, admin_token} = AdminToken.build_email_token(admin, "change:#{current_email}")

    Repo.insert!(admin_token)
    AdminNotifier.deliver_update_email_instructions(admin, update_email_url_fun.(encoded_token))
  end

  def change_admin_password(admin, attrs \\ %{}) do
    Account.password_changeset(admin, attrs, hash_password: false)
  end

  def update_admin_password(admin, password, attrs) do
    changeset =
      admin
      |> Account.password_changeset(attrs)
      |> Account.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, changeset)
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin: admin}} -> {:ok, admin}
      {:error, :admin, changeset, _} -> {:error, changeset}
    end
  end

  def generate_admin_session_token(admin) do
    {token, admin_token} = AdminToken.build_session_token(admin)
    Repo.insert!(admin_token)
    token
  end

  def get_admin_by_session_token(token) do
    {:ok, query} = AdminToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_admin_session_token(token) do
    Repo.delete_all(AdminToken.by_token_and_context_query(token, "session"))
    :ok
  end

  def deliver_admin_confirmation_instructions(%Account{} = admin, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if admin.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, admin_token} = AdminToken.build_email_token(admin, "confirm")
      Repo.insert!(admin_token)
      AdminNotifier.deliver_confirmation_instructions(admin, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_admin(token) do
    with {:ok, query} <- AdminToken.verify_email_token_query(token, "confirm"),
         %Account{} = admin <- Repo.one(query),
         {:ok, %{admin: admin}} <- Repo.transaction(confirm_admin_multi(admin)) do
      {:ok, admin}
    else
      _ -> :error
    end
  end

  defp confirm_admin_multi(admin) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, Account.confirm_changeset(admin))
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, ["confirm"]))
  end

  def deliver_admin_reset_password_instructions(%Account{} = admin, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, admin_token} = AdminToken.build_email_token(admin, "reset_password")
    Repo.insert!(admin_token)
    AdminNotifier.deliver_reset_password_instructions(admin, reset_password_url_fun.(encoded_token))
  end

  def get_admin_by_reset_password_token(token) do
    with {:ok, query} <- AdminToken.verify_email_token_query(token, "reset_password"),
         %Account{} = admin <- Repo.one(query) do
      admin
    else
      _ -> nil
    end
  end

  def reset_admin_password(admin, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:admin, Account.password_changeset(admin, attrs))
    |> Ecto.Multi.delete_all(:tokens, AdminToken.by_admin_and_contexts_query(admin, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{admin: admin}} -> {:ok, admin}
      {:error, :admin, changeset, _} -> {:error, changeset}
    end
  end
end
