USE Bascula
GO

CREATE PROCEDURE ProcCreateTaller
	@NombreTaller NVARCHAR(50),
	@DescripTaller NVARCHAR(MAX),
	@CodCliente INT,
	@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		
		IF @NombreTaller IS NULL OR @DescripTaller IS NULL OR @CodCliente IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: El nombre de la reparación en taller, su descripción y el código del cliente es un campo obligatorio.';
			RETURN;
		END

		IF (LEN(TRIM(@NombreTaller)) < 3 OR LEN(TRIM(@NombreTaller)) > 50)
		BEGIN
			SET @Mensaje = 'ERROR: El nombre del de la reparación en taller tiene que tener de 3 a 50 caracteres.';
			RETURN;
		END

		IF (LEN(TRIM(@DescripTaller)) < 5)
		BEGIN
			SET @Mensaje = 'ERROR: La descripción tiene que tener mínimo 5 caracteres.';
			RETURN;
		END
		BEGIN TRANSACTION;

		DECLARE @exist_Cliente BIT = (SELECT EstadoCL FROM Cliente WITH (UPDLOCK, ROWLOCK)
							       WHERE CodCliente = @CodCliente);

		IF @exist_Cliente IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Código de Cliente ('+ TRY_CONVERT(varchar(10),@CodCliente) +') no encontrado en el sistema, revise su código/ID.';
			RETURN;
		END

		IF @exist_Cliente = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: El cliente del código ('+ TRY_CONVERT(varchar(10),@CodCliente) +') está inactivo.';
			RETURN;
		END

		IF EXISTS (SELECT 1 FROM Taller WITH (UPDLOCK, ROWLOCK)
				   WHERE NombreTaller = @NombreTaller
				   AND EstadoTaller = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La reparación en taller "'+ @NombreTaller +'" ya está registrada y activa.';
			RETURN;
		END

		INSERT INTO Taller (NombreTaller, DescripTaller, CodCliente)
		VALUES (lower(TRIM(@NombreTaller)), (lower(TRIM(@DescripTaller))), @CodCliente);

		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al registrar la reparación en taller.';
			RETURN;
		END

		COMMIT TRANSACTION;
		SET @Mensaje = 'Reparación en taller registrado correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		SET @Mensaje = 'Error al registrar la reparación en taller: ' + ERROR_MESSAGE();
	END CATCH
END