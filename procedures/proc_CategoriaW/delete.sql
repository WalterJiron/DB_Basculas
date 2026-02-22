USE Bascula;

GO

CREATE PROC ProcDeleteCategoria
    @CodCat INT,
    @Mensaje NVARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar codigo de categoria
        IF @CodCat IS NULL
        BEGIN
            SET @Mensaje = 'El código de categoría es obligatorio';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado
        DECLARE @EstadoActual BIT;
        
        SELECT @EstadoActual = EstadoCat
        FROM Categoria WITH (UPDLOCK, HOLDLOCK)
        WHERE CodCat = @CodCat;

        IF @EstadoActual IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría no existe en la base de datos';
            RETURN;
        END

        IF @EstadoActual = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'La categoría ya se encuentra eliminada';
            RETURN;
        END

        -- Verificar si hay productos asociados a la categoria
        IF EXISTS (
            SELECT 1 
            FROM Producto AS P 
            JOIN SubCategoria AS SBC
            ON SBC.CodSubCat = P.CodSubCat
            WHERE  SBC.CodCat = @CodCat AND P.EstadoProd = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'No se puede eliminar, existen productos activos en esta categoría';
            RETURN;
        END

        -- Actualizar estado
        UPDATE Categoria SET
            EstadoCat = 0,
            DateDelete = SYSDATETIMEOFFSET()
        WHERE CodCat = @CodCat;

        -- Verificar actualizacion
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al eliminar la categoría';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Categoría desactivada correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @Mensaje = 'Error al desactivar categoría: ' + ERROR_MESSAGE();
    END CATCH
END;