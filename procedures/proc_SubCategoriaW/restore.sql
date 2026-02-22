USE Bascula;

GO

CREATE PROC ProcRestoreSubCategoria
    @CodSubCat INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar codigo de subcategoria
        IF @CodSubCat IS NULL
        BEGIN
            SET @Mensaje = 'El código de subcategoría es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        DECLARE @NombreSubCat NVARCHAR(50);
        DECLARE @CodCat INT;
        
        SELECT @EstadoActual = EstadoSubCat,
               @NombreSubCat = NombreSubCat,
               @CodCat = CodCat
        FROM SubCategoria WITH (UPDLOCK, HOLDLOCK)
        WHERE CodSubCat = @CodSubCat;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría ya se encuentra activa';
            RETURN;
        END

        -- Verificar que la categoria padre este activa
        IF NOT EXISTS (
            SELECT 1 FROM Categoria WITH (UPDLOCK)
            WHERE CodCat = @CodCat AND EstadoCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, la categoría padre está inactiva';
            RETURN;
        END

        -- Verificar que el nombre no este siendo usado por otra subcategoria activa
        IF EXISTS (
            SELECT 1 FROM SubCategoria WITH (UPDLOCK)
            WHERE NombreSubCat = @NombreSubCat
              AND CodSubCat <> @CodSubCat
              AND EstadoSubCat = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede recuperar, ya existe una subcategoría activa con ese nombre';
            RETURN;
        END

        UPDATE SubCategoria SET
            EstadoSubCat = 1,
            DateDelete = NULL
        WHERE CodSubCat = @CodSubCat;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al recuperar la subcategoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Subcategoría recuperada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al recuperar subcategoría: ' + ERROR_MESSAGE();
    END CATCH
END;