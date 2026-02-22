USE Bascula
GO

CREATE PROC ProcDeleteTaller -- Báscula en el taller reparada
@CodTaller INT,
@Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		IF @CodTaller IS NULL
		BEGIN
			SET @Mensaje = 'ERROR: Debe proporcionar el código del taller.';
			RETURN;
		END
		
		BEGIN TRANSACTION;
		
		DECLARE @exist_Taller BIT;
        SET @exist_Taller = (SELECT EstadoTaller 
							 FROM Taller WITH (UPDLOCK, ROWLOCK)
							 WHERE CodTaller = @CodTaller);
		
		IF @exist_Taller IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: Reparación en taller del código ('+ TRY_CONVERT(nvarchar(10),@CodTaller) +') no registrado en el sistema, revise el códido/ID.';
			RETURN;
		END
		
		IF @exist_Taller = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'ERROR: La báscula en el taller con el código ('+ TRY_CONVERT(varchar(10),@CodTaller) +') ya está marcada como "reparada".';
			RETURN;
		END

		UPDATE Taller
		SET EstadoTaller = 0,
			DateDelete = SYSDATETIMEOFFSET() -- Este realmente se vuelve la fecha en la que se terminó de reparar la báscula
		WHERE CodTaller = @CodTaller;
		
		IF @@ROWCOUNT <> 1
		BEGIN
			ROLLBACK TRANSACTION;
			SET @Mensaje = 'Error inesperado al marcar como "reparada" la báscula en el taller.';
			RETURN;
		END
		
		COMMIT TRANSACTION;
		SET @Mensaje = 'Báscula en el taller marcado como "reparada" correctamente.';
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
			
		SET @Mensaje = 'Error al marcar como "reparada" la báscula en el taller: ' + ERROR_MESSAGE();
	END CATCH
END