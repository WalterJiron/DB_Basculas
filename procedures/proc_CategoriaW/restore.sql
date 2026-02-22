USE Bascula;

GO

CREATE PROC ProcRestoreCategoria
    @CodCat INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar código de categoria
        IF @CodCat IS NULL
        BEGIN
            SET @Mensaje = 'El código de categoría es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        DECLARE @NombreCat NVARCHAR(50);
        
        SELECT @EstadoActual = EstadoCat,
               @NombreCat = NombreCat
        FROM Categoria WITH (UPDLOCK, HOLDLOCK)
        WHERE CodCat = @CodCat;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría ya se encuentra activa';
            RETURN;
        END

        -- Verificar que el nombre no este siendo usado por otra categoria activa
        IF EXISTS (
            SELECT 1 FROM Categoria WITH (UPDLOCK)
            WHERE NombreCat = @NombreCat AND CodCat <> @CodCat AND EstadoCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, ya existe una categoría activa con ese nombre';
            RETURN;
        END

        UPDATE Categoria SET
            EstadoCat = 1,
            DateDelete = NULL
        WHERE CodCat = @CodCat;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar la categoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Categoría recuperada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al recuperar categoría: ' + ERROR_MESSAGE();
    END CATCH
END;