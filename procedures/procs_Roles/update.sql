USE Bascula;

GO

CREATE PROC ProcUpdateRol
    @CodigoRol UNIQUEIDENTIFIER,
    @NombreRol VARCHAR(50),  
    @Descripcion VARCHAR(MAX), 
    @Mensaje VARCHAR(100) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @CodigoRol IS NULL OR @NombreRol IS NULL OR @Descripcion IS NULL
        BEGIN
            SET @Mensaje = 'Todos los campos son obligatorios';
            RETURN;
        END

        IF LEN(TRIM(@NombreRol)) < 3 AND LEN(TRIM(@NombreRol)) > 50
        BEGIN
            SET @Mensaje = 'El nombre del rol debe tener al menos 3 caracteres y maximo 50';
            RETURN;
        END

        IF LEN(TRIM(@Descripcion)) < 10
        BEGIN
            SET @Mensaje = 'La descripcion debe tener al menos 10 caracteres';
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Verificar existencia y estado 
        DECLARE @existRol BIT;
        SET @existRol = (
            SELECT EstadoRol FROM Rol WITH (UPDLOCK, ROWLOCK)
            WHERE CodigoRol = @CodigoRol
        );

        IF @existRol IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El rol no existe en la base de datos';
            RETURN;
        END

        IF @existRol = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'El rol se encuentra inactivo';
            RETURN;
        END

        -- Verificar nombre unico 
        IF EXISTS (
            SELECT 1 FROM Rol WITH (UPDLOCK)
            WHERE NombreRol = TRIM(@NombreRol)
              AND CodigoRol <> @CodigoRol
              AND EstadoRol = 1
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Ya existe un rol activo con ese nombre';
            RETURN;
        END

        UPDATE Rol SET
            NombreRol = TRIM(@NombreRol),
            DescripRol = TRIM(@Descripcion),
            DateUpdate = SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time'
        WHERE CodigoRol = @CodigoRol;

        -- Verificar que se actualizo exactamente 1 registro
        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            SET @Mensaje = 'Error inesperado al actualizar el rol';
            RETURN;
        END

        COMMIT TRANSACTION;
        SET @Mensaje = 'Rol actualizado correctamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Mensaje = 'Error al actualizar rol: ' + ERROR_MESSAGE();
    END CATCH
END;