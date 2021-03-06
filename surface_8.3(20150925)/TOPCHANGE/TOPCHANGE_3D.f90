    MODULE TOPCHANGE_3D
    USE REMESHING_3D
    
    IMPLICIT NONE

    CONTAINS
    
    SUBROUTINE REMOVE_CERTAIN_FACES(TYP, B_REMOVE_FACE)
    IMPLICIT NONE
    
    INTEGER :: TYP
    LOGICAL :: B_REMOVE_FACE(:)
    
    INTEGER :: I, J
    LOGICAL :: B
    INTEGER :: NEWPOINT_NUM, NEWFACE_NUM
    REAL(8), ALLOCATABLE :: NEWPOINT(:,:) 
    INTEGER, ALLOCATABLE :: NEWFACE(:,:)
    INTEGER, ALLOCATABLE :: POINT_INDEX(:)
    INTEGER, ALLOCATABLE :: FACE_INDEX(:)
    
    TYPE(SURFACE_TYPE), POINTER :: SURFACE_CURRENT
    
    IF (TYP==0) THEN
        SURFACE_CURRENT => SURFACE_FLUID
    END IF
    IF (TYP==1) THEN
        SURFACE_CURRENT => SURFACE_PROPEL
    END IF
    IF (TYP==2) THEN
        SURFACE_CURRENT => SURFACE_CASE
    END IF

    ALLOCATE(NEWPOINT(3,SURFACE_CURRENT%SURFACE_POINTS_NUM))
    ALLOCATE(NEWFACE(3,SURFACE_CURRENT%SURFACE_FACES_NUM))
    ALLOCATE(POINT_INDEX(SURFACE_CURRENT%SURFACE_POINTS_NUM))
    ALLOCATE(FACE_INDEX(SURFACE_CURRENT%SURFACE_FACES_NUM))

    POINT_INDEX(:) = 0
    FACE_INDEX(:) = 0

    NEWPOINT_NUM = 0

    DO I = 1, SURFACE_CURRENT%SURFACE_POINTS_NUM
        B = .FALSE.
        DO J = 1, SURFACE_CURRENT%POINT_FACE_CONNECTION_NUM(I)
            IF(.NOT. B_REMOVE_FACE(SURFACE_CURRENT%POINT_FACE_CONNECTION(J,I)) THEN
                B = .TRUE.
            END IF
        END DO
        
        IF(B) THEN
            NEWPOINT_NUM = NEWPOINT_NUM+1
            NEWPOINT(:,NEWPOINT_NUM) = SURFACE_CURRENT%SURFACE_POINTS(:,I)
            POINT_INDEX(I) = NEWPOINT_NUM
        END IF
    END DO

    NEWFACE_NUM = 0

    DO J = 1, SURFACE_CURRENT%SURFACE_FACES_NUM
        IF(.NOT. B_REMOVE_FACE(J)) THEN
            NEWFACE_NUM = NEWFACE_NUM+1
            NEWFACE(:,NEWFACE_NUM) = SURFACE_CURRENT%SURFACE_FACES(:,J)
            FACE_INDEX(J) = NEWFACE_NUM
        END IF
    END DO

    CALL NEW_POINTFACE_INDEX(TYP, NEWPOINT_NUM, NEWPOINT, NEWFACE_NUM, NEWFACE, POINT_INDEX, FACE_INDEX)

    !IF(TYP==1) THEN
    !    CALL CLASSIFY_PATCH(1)
    !END IF

    DEALLOCATE(NEWPOINT)
    DEALLOCATE(NEWFACE)
    DEALLOCATE(POINT_INDEX)
    DEALLOCATE(FACE_INDEX)
    
    END SUBROUTINE
    
    SUBROUTINE FIND_REMOVE_FACES(TYP, FLAG)
    IMPLICIT NONE
    INTEGER :: TYP
    INTEGER :: I, J, K, IPZ, DIR, PAIR_NUM
    !INTEGER :: I1, I2, J1, J2, IPZ1, IPZ2, IND
    REAL(8) :: R !, R1, R2, R3
    !INTEGER, ALLOCATABLE :: PATCH_PARENT(:), PATCH_BEFORE_INDEX(:)
    LOGICAL :: B, FLAG, TEMPFLAG, THINFLAG

    TYPE(SURFACE_TYPE), POINTER :: SURFACE_CURRENT
    
    IF (TYP==0) THEN
        SURFACE_CURRENT => SURFACE_FLUID
    END IF
    IF (TYP==1) THEN
        SURFACE_CURRENT => SURFACE_PROPEL
    END IF
    IF (TYP==2) THEN
        SURFACE_CURRENT => SURFACE_CASE
    END IF

    FLAG = .FALSE.

    TEMPFLAG = .FALSE.
    THINFLAG = .FALSE.

    B = .TRUE.
    DIR = 0
    !ALLOCATE(PATCH_PARENT(SURFACE_PROPEL%SURFACE_FACES_NUM))

    !DO J=1,SURFACE_PROPEL%SURFACE_PATCHES_NUM
    !    DO I=1,SURFACE_PROPEL%SURFACE_FACES_NUM
    !        IF(SURFACE_PROPEL%FACE_LOCATION(I) .EQ. J) THEN
    !            I1 = SURFACE_PROPEL%SURFACE_EDGES(1,I)
    !            I2 = SURFACE_PROPEL%SURFACE_EDGES(2,I)
    !            J1 = SURFACE_PROPEL%POINT_EDGE_CONNECTION(1,I1)
    !            J2 = SURFACE_PROPEL%POINT_EDGE_CONNECTION(2,I2)
    !            IPZ = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, I)
    !            IPZ1 = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, J1)
    !            IPZ2 = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, J2)
    !            		   
    !            IF(IPZ.NE.0 .AND. IPZ1 .NE. 0 .AND. IPZ2 .NE. 0) THEN
    !                CALL DISTANCE_FACE_FACE_TYPE(I,1,IPZ,1,DIR,  R1,B)
    !                CALL DISTANCE_FACE_FACE_TYPE(J1,1,IPZ1,1,DIR,  R2,B)
    !                CALL DISTANCE_FACE_FACE_TYPE(J2,1,IPZ2,1,DIR,  R3,B)
    !                IF(MAX(ABS(R1),MAX(ABS(R2),ABS(R3))) .LT. SURFACE_FLUID%MESH_SIZE * 10.) THEN
    !                    IND = I
    !                    THINFLAG = .TRUE.
    !                    SURFACE_PROPEL%SURFACE_PATCHES_TOPCHANGE_TYP(SURFACE_PROPEL%FACE_LOCATION(IND)) = 11
    !                    EXIT
    !                END IF
    !            END IF
    !        END IF
    !    END DO
    !END DO

    DO I=1,SURFACE_PROPEL%SURFACE_FACES_NUM
        IPZ = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, I)
        IF(IPZ.NE.0) THEN
            CALL DISTANCE_FACE_FACE_TYPE(I,1,IPZ,1,DIR,  R,B)
            IF(R < SURFACE_FLUID%MESH_SIZE * THIN_REGION_ATTACHMENT) THEN
                TEMPFLAG = .TRUE.
                EXIT
            END IF
        END IF
    END DO

    PAIR_NUM = 0
    IF(TEMPFLAG) THEN
        DO I=1,SURFACE_PROPEL%SURFACE_FACES_NUM
            IPZ = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, I)

            IF(IPZ.NE.0) THEN
                IF(SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1,IPZ) .EQ. I) THEN
                    IF(PAIR_NUM .EQ. 0) THEN
                        PAIR_NUM = PAIR_NUM + 1
                        MATCH_INDEX(PAIR_NUM,1) = I
                        MATCH_INDEX(PAIR_NUM,2) = IPZ
                    ELSE
                        B = .TRUE.
                        DO J=1,PAIR_NUM
                            IF(MATCH_INDEX(J,2) .EQ. I) THEN
                                B = .FALSE.
                                EXIT
                            END IF
                        END DO

                        IF(B) THEN
                            PAIR_NUM = PAIR_NUM + 1
                            MATCH_INDEX(PAIR_NUM,1) = I
                            MATCH_INDEX(PAIR_NUM,2) = IPZ
                        END IF
                    END IF
                END IF
            END IF

        END DO

        DO K=1,PAIR_NUM
            CALL DISTANCE_FACE_FACE_TYPE(MATCH_INDEX(K,1),1,MATCH_INDEX(K,2),1,DIR,  R,B)
            IF(MATCH_INDEX(K,2) .NE. 0) THEN
                IF(R < SURFACE_FLUID%MESH_SIZE * THIN_REGION_ATTACHMENT * 1.5) THEN
                    SURFACE_PROPEL%SURFACE_PATCHES_TOPCHANGE_TYP(SURFACE_PROPEL%FACE_LOCATION(MATCH_INDEX(K,1))) = 3

                    CALL REMOVE_LARGE_REGION(1, SURFACE_PROPEL%FACE_LOCATION(MATCH_INDEX(K,1)))
                    !CALL ATTACH_TWO_EDGES(1, MATCH_INDEX(K,1), MATCH_INDEX(K,2))
                    FLAG = .TRUE.
                    EXIT
                END IF
            END IF
        END DO

        CALL RESET_PATCH(1)!, PATCH_BEFORE_INDEX = PATCH_BEFORE_INDEX)                
        !CALL REMOVE_SMALL_REGIONS(1, PATCH_BEFORE_INDEX, PATCH_PARENT = PATCH_PARENT, FLAG = FLAG)
    END IF

    !DEALLOCATE(PATCH_PARENT)

    END SUBROUTINE
    
    SUBROUTINE REMOVE_LARGE_REGION(TYP, REGION_NUM)
    IMPLICIT NONE
    INTEGER :: TYP
    INTEGER :: I, J
    INTEGER :: ITER, REGION_NUM
    LOGICAL :: B
    INTEGER :: NEWPOINT_NUM, NEWFACE_NUM
    REAL(8), ALLOCATABLE :: NEWPOINT(:,:) 
    INTEGER, ALLOCATABLE :: NEWFACE(:,:)
    INTEGER, ALLOCATABLE :: POINT_INDEX(:)
    INTEGER, ALLOCATABLE :: FACE_INDEX(:)
    TYPE(SURFACE_TYPE), POINTER :: SURFACE_CURRENT

    
    IF (TYP==0) THEN
        SURFACE_CURRENT => SURFACE_FLUID
    END IF
    IF (TYP==1) THEN
        SURFACE_CURRENT => SURFACE_PROPEL
    END IF
    IF (TYP==2) THEN
        SURFACE_CURRENT => SURFACE_CASE
    END IF

    ALLOCATE(NEWPOINT(3,SURFACE_CURRENT%SURFACE_POINTS_NUM))
    ALLOCATE(NEWFACE(3,SURFACE_CURRENT%SURFACE_FACES_NUM))
    ALLOCATE(POINT_INDEX(SURFACE_CURRENT%SURFACE_POINTS_NUM))
    ALLOCATE(FACE_INDEX(SURFACE_CURRENT%SURFACE_FACES_NUM))

    POINT_INDEX(:) = 0
    FACE_INDEX(:) = 0

    NEWPOINT_NUM = 0
    B = .TRUE.
    ITER = 1


    DO WHILE(B)
        B = .FALSE.
        DO I = 1, SURFACE_CURRENT%SURFACE_POINTS_NUM
            IF(SURFACE_CURRENT%FACE_LOCATION(SURFACE_CURRENT%POINT_FACE_CONNECTION(1,I))==ITER) THEN
                B = .TRUE.
                IF(ITER .NE. REGION_NUM) THEN
                    NEWPOINT_NUM = NEWPOINT_NUM+1
                    NEWPOINT(:,NEWPOINT_NUM) = SURFACE_CURRENT%SURFACE_POINTS(:,I)
                    POINT_INDEX(I) = NEWPOINT_NUM
                END IF
            END IF
        END DO
        ITER = ITER + 1
    END DO

    NEWFACE_NUM = 0
    B = .TRUE.
    ITER = 1

    DO WHILE(B)
        B = .FALSE.
        DO J = 1, SURFACE_CURRENT%SURFACE_FACES_NUM
            IF(SURFACE_CURRENT%FACE_LOCATION(J)==ITER) THEN
                B = .TRUE.
                IF(ITER .NE. REGION_NUM) THEN
                    NEWFACE_NUM = NEWFACE_NUM+1
                    NEWFACE(:,NEWFACE_NUM) = SURFACE_CURRENT%SURFACE_FACES(:,J)
                    FACE_INDEX(J) = NEWFACE_NUM
                END IF
            END IF
        END DO
        ITER = ITER + 1
    END DO

    !write(*,*) 'NEWPOINT NUM', NEWPOINT_NUM
    !write(*,*) 'NEWFACE NUM', NEWFACE_NUM

    CALL NEW_POINTFACE_INDEX(TYP, NEWPOINT_NUM, NEWPOINT, NEWFACE_NUM, NEWFACE, POINT_INDEX, FACE_INDEX)

    !IF(TYP==1) THEN
    !    CALL CLASSIFY_PATCH(1)
    !END IF

    DEALLOCATE(NEWPOINT)
    DEALLOCATE(NEWFACE)
    DEALLOCATE(POINT_INDEX)
    DEALLOCATE(FACE_INDEX)

    END SUBROUTINE REMOVE_LARGE_REGION


    SUBROUTINE ZIPPER_PROPEL_IMPACT_ZONE(FLAG)
    IMPLICIT NONE
    INTEGER :: I, J, K, IPZ, DIR, PAIR_NUM
    !INTEGER :: I1, I2, J1, J2, IPZ1, IPZ2, IND
    REAL(8) :: R !, R1, R2, R3
    INTEGER, ALLOCATABLE :: MATCH_INDEX(:,:)!, PATCH_PARENT(:), PATCH_BEFORE_INDEX(:)
    LOGICAL :: B, FLAG, TEMPFLAG, THINFLAG

    FLAG = .FALSE.

    TEMPFLAG = .FALSE.
    THINFLAG = .FALSE.
    B = .TRUE.
    DIR = 0
    ALLOCATE(MATCH_INDEX(SURFACE_PROPEL%SURFACE_FACES_NUM,2))
    !ALLOCATE(PATCH_PARENT(SURFACE_PROPEL%SURFACE_FACES_NUM))

    !DO J=1,SURFACE_PROPEL%SURFACE_PATCHES_NUM
    !    DO I=1,SURFACE_PROPEL%SURFACE_FACES_NUM
    !        IF(SURFACE_PROPEL%FACE_LOCATION(I) .EQ. J) THEN
    !            I1 = SURFACE_PROPEL%SURFACE_EDGES(1,I)
    !            I2 = SURFACE_PROPEL%SURFACE_EDGES(2,I)
    !            J1 = SURFACE_PROPEL%POINT_EDGE_CONNECTION(1,I1)
    !            J2 = SURFACE_PROPEL%POINT_EDGE_CONNECTION(2,I2)
    !            IPZ = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, I)
    !            IPZ1 = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, J1)
    !            IPZ2 = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, J2)
    !            		   
    !            IF(IPZ.NE.0 .AND. IPZ1 .NE. 0 .AND. IPZ2 .NE. 0) THEN
    !                CALL DISTANCE_FACE_FACE_TYPE(I,1,IPZ,1,DIR,  R1,B)
    !                CALL DISTANCE_FACE_FACE_TYPE(J1,1,IPZ1,1,DIR,  R2,B)
    !                CALL DISTANCE_FACE_FACE_TYPE(J2,1,IPZ2,1,DIR,  R3,B)
    !                IF(MAX(ABS(R1),MAX(ABS(R2),ABS(R3))) .LT. SURFACE_FLUID%MESH_SIZE * 10.) THEN
    !                    IND = I
    !                    THINFLAG = .TRUE.
    !                    SURFACE_PROPEL%SURFACE_PATCHES_TOPCHANGE_TYP(SURFACE_PROPEL%FACE_LOCATION(IND)) = 11
    !                    EXIT
    !                END IF
    !            END IF
    !        END IF
    !    END DO
    !END DO

    DO I=1,SURFACE_PROPEL%SURFACE_FACES_NUM
        IPZ = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, I)
        IF(IPZ.NE.0) THEN
            CALL DISTANCE_FACE_FACE_TYPE(I,1,IPZ,1,DIR,  R,B)
            IF(R < SURFACE_FLUID%MESH_SIZE * THIN_REGION_ATTACHMENT) THEN
                TEMPFLAG = .TRUE.
                EXIT
            END IF
        END IF
    END DO

    PAIR_NUM = 0
    IF(TEMPFLAG) THEN
        DO I=1,SURFACE_PROPEL%SURFACE_FACES_NUM
            IPZ = SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1, I)

            IF(IPZ.NE.0) THEN
                IF(SURFACE_PROPEL%FACE_IMPACT_ZONE(1+1,IPZ) .EQ. I) THEN
                    IF(PAIR_NUM .EQ. 0) THEN
                        PAIR_NUM = PAIR_NUM + 1
                        MATCH_INDEX(PAIR_NUM,1) = I
                        MATCH_INDEX(PAIR_NUM,2) = IPZ
                    ELSE
                        B = .TRUE.
                        DO J=1,PAIR_NUM
                            IF(MATCH_INDEX(J,2) .EQ. I) THEN
                                B = .FALSE.
                                EXIT
                            END IF
                        END DO

                        IF(B) THEN
                            PAIR_NUM = PAIR_NUM + 1
                            MATCH_INDEX(PAIR_NUM,1) = I
                            MATCH_INDEX(PAIR_NUM,2) = IPZ
                        END IF
                    END IF
                END IF
            END IF

        END DO

        DO K=1,PAIR_NUM
            CALL DISTANCE_FACE_FACE_TYPE(MATCH_INDEX(K,1),1,MATCH_INDEX(K,2),1,DIR,  R,B)
            IF(MATCH_INDEX(K,2) .NE. 0) THEN
                IF(R < SURFACE_FLUID%MESH_SIZE * THIN_REGION_ATTACHMENT * 1.5) THEN
                    SURFACE_PROPEL%SURFACE_PATCHES_TOPCHANGE_TYP(SURFACE_PROPEL%FACE_LOCATION(MATCH_INDEX(K,1))) = 3

                    CALL REMOVE_LARGE_REGION(1, SURFACE_PROPEL%FACE_LOCATION(MATCH_INDEX(K,1)))
                    !CALL ATTACH_TWO_EDGES(1, MATCH_INDEX(K,1), MATCH_INDEX(K,2))
                    FLAG = .TRUE.
                    EXIT
                END IF
            END IF
        END DO

        CALL RESET_PATCH(1)!, PATCH_BEFORE_INDEX = PATCH_BEFORE_INDEX)                
        !CALL REMOVE_SMALL_REGIONS(1, PATCH_BEFORE_INDEX, PATCH_PARENT = PATCH_PARENT, FLAG = FLAG)
    END IF

    DEALLOCATE(MATCH_INDEX)
    !DEALLOCATE(PATCH_PARENT)

    END SUBROUTINE ZIPPER_PROPEL_IMPACT_ZONE




    END MODULE
