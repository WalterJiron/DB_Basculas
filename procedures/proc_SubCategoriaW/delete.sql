USE Bascula;

GO

CREATE PROC ProcDeleteSubCategoria
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
        
        SELECT @EstadoActual = EstadoSubCat
        FROM SubCategoria WITH (UPDLOCK, HOLDLOCK)
        WHERE CodSubCat = @CodSubCat;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La subcategoría ya se encuentra eliminada';
            RETURN;
        END

        -- Verificar si hay productos asociados a la subcategoría
        IF EXISTS (
            SELECT 1 FROM Producto 
            WHERE CodSubCat = @CodSubCat AND EstadoProd = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede eliminar, existen productos activos en esta subcategoría';
            RETURN;
        END

        UPDATE SubCategoria SET
            EstadoSubCat = 0,
            DateDelete = SYSDATETIMEOFFSET() 
        WHERE CodSubCat = @CodSubCat;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar la subcategoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Subcategoría desactivada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al desactivar subcategoría: ' + ERROR_MESSAGE();
    END CATCH
END;