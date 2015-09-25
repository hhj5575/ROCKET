MODULE HASHING_3D
    USE SURFACE_MODULE_3D
    
    IMPLICIT NONE
    
    TYPE HASH_ELEMENT
        INTEGER :: I0
        
        TYPE(HASH_ELEMENT), POINTER :: NEXT
    END TYPE
    
    TYPE HASH_ELEMENT_ARRAY
        INTEGER :: NUM
        TYPE(HASH_ELEMENT), POINTER :: HEAD
    END TYPE
    
    TYPE HASH
        INTEGER :: TYP
        INTEGER :: ELEMENT_TYP
        REAL(8) :: HASH_DOMAIN_MAX(3), HASH_DOMAIN_MIN(3)
        INTEGER :: HASH_NUM1, HASH_NUM2, HASH_NUM3
        
        TYPE(HASH_ELEMENT_ARRAY), ALLOCATABLE :: ELEMENT(:,:,:)
    END TYPE
    
    CONTAINS
    
    SUBROUTINE INSERT_ELEMENT(HASH0, INDEX1, INDEX2, INDEX3, I0)
        TYPE(HASH) :: HASH0
        INTEGER :: INDEX1, INDEX2, INDEX3
        TYPE(HASH_ELEMENT), POINTER :: NEW_ELEMENT
        INTEGER :: I0
        
        IF(INDEX1 >= 1 .AND. INDEX1 <= HASH0%HASH_NUM1 .AND. INDEX2 >=1 .AND. INDEX2 <= HASH0%HASH_NUM2 .AND. INDEX3>=1 .AND. INDEX3 <= HASH0%HASH_NUM3) THEN
            HASH0%ELEMENT(INDEX1, INDEX2, INDEX3)%NUM = HASH0%ELEMENT(INDEX1, INDEX2, INDEX3)%NUM + 1
            
            ALLOCATE(NEW_ELEMENT)
            NEW_ELEMENT%I0 = I0
            
            CALL INSERT_ELEMENT_POINTER(HASH0%ELEMENT(INDEX1, INDEX2, INDEX3)%HEAD, NEW_ELEMENT)
        END IF
        
    END SUBROUTINE
    
    SUBROUTINE INSERT_ELEMENT_POINTER(HEAD, NEW_ELEMENT)
        TYPE(HASH_ELEMENT), POINTER :: HEAD
        TYPE(HASH_ELEMENT), POINTER :: NEW_ELEMENT
        
        IF(.NOT. ASSOCIATED(HEAD)) THEN
            NULLIFY(NEW_ELEMENT%NEXT)
        ELSE
            NEW_ELEMENT%NEXT => HEAD
        END IF
        
        HEAD => NEW_ELEMENT
    END SUBROUTINE
    
    SUBROUTINE REMOVE_ALL_ELEMENT_POINTER(HEAD)
        TYPE(HASH_ELEMENT), POINTER :: HEAD
        TYPE(HASH_ELEMENT), POINTER :: CURRENT
        TYPE(HASH_ELEMENT), POINTER :: TEMP
        
        CURRENT => HEAD
        
        DO WHILE(ASSOCIATED(CURRENT))
            TEMP => CURRENT%NEXT
            DEALLOCATE(CURRENT)
            CURRENT => TEMP
        END DO
        
        NULLIFY(CURRENT)
        NULLIFY(TEMP)
        NULLIFY(HEAD)
        
    END SUBROUTINE
    
    SUBROUTINE REMOVE_HASH(HASH0)
        TYPE(HASH) :: HASH0
        
        INTEGER :: I,J,K
        
        DO I=1,HASH0%HASH_NUM1
            DO J=1,HASH0%HASH_NUM2
                DO K=1,HASH0%HASH_NUM3
                    CALL REMOVE_ALL_ELEMENT_POINTER(HASH0%ELEMENT(I,J,K)%HEAD)
                END DO
            END DO
        END DO
        
        DEALLOCATE(HASH0%ELEMENT)
        
    END SUBROUTINE REMOVE_HASH
    
    SUBROUTINE FIND_HASH_INDEX(HASH0, V, INDEX1, INDEX2, INDEX3)
        TYPE(HASH) :: HASH0
        REAL(8) :: V(3)
        INTEGER :: INDEX1, INDEX2, INDEX3
        
        INDEX1 = CEILING(REAL(HASH0%HASH_NUM1) * (V(1)-HASH0%HASH_DOMAIN_MIN(1))/(HASH0%HASH_DOMAIN_MAX(1)- HASH0%HASH_DOMAIN_MIN(1)))
        INDEX2 = CEILING(REAL(HASH0%HASH_NUM2) * (V(2)-HASH0%HASH_DOMAIN_MIN(2))/(HASH0%HASH_DOMAIN_MAX(2)- HASH0%HASH_DOMAIN_MIN(2)))
        INDEX3 = CEILING(REAL(HASH0%HASH_NUM3) * (V(3)-HASH0%HASH_DOMAIN_MIN(3))/(HASH0%HASH_DOMAIN_MAX(3)- HASH0%HASH_DOMAIN_MIN(3)))
    END SUBROUTINE
    
    SUBROUTINE SET_HASH_TYP(TYP, ELEMENT_TYP, HASH0)
        INTEGER :: TYP
        INTEGER :: ELEMENT_TYP
        TYPE(HASH) :: HASH0
        
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
        
        HASH0%TYP = TYP
        
        CALL SET_HASH(SURFACE_CURRENT%SURFACE_POINTS_NUM, SURFACE_CURRENT%SURFACE_POINTS, SURFACE_CURRENT%SURFACE_FACES_NUM, SURFACE_CURRENT%SURFACE_FACES, ELEMENT_TYP, DOMAIN_MAX, DOMAIN_MIN, HASH0, SURFACE_CURRENT%HASH_SIZE)
        
    END SUBROUTINE
    
    SUBROUTINE SET_HASH(POINT_NUM, POINT, FACE_NUM, FACE, ELEMENT_TYP, HASH_DOMAIN_MAX, HASH_DOMAIN_MIN, HASH0, HASH_SIZE0)
        INTEGER :: POINT_NUM
        REAL(8) :: POINT(3,POINT_NUM)
        INTEGER :: FACE_NUM
        INTEGER :: FACE(3,FACE_NUM)
        
        INTEGER :: ELEMENT_TYP
        
        REAL(8) :: HASH_DOMAIN_MAX(3)
        REAL(8) :: HASH_DOMAIN_MIN(3)
        
        TYPE(HASH) :: HASH0
        REAL(8), OPTIONAL :: HASH_SIZE0
        REAL(8) :: HASH_SIZE
        
        INTEGER :: HASH_POINT_NUM
        REAL(8), ALLOCATABLE :: HASH_POINT(:,:)
        
        INTEGER :: I,J,K
        INTEGER :: INDEX1, INDEX2, INDEX3
        
        REAL(8) :: V1(3), V2(3), V3(3), L
        
        IF(PRESENT(HASH_SIZE0)) THEN
            HASH_SIZE = HASH_SIZE0
        ELSE
            HASH_SIZE = 0.
            DO I=1,FACE_NUM
                V1 = POINT(:,FACE(2,I)) - POINT(:,FACE(1,I))
                V2 = POINT(:,FACE(3,I)) - POINT(:,FACE(2,I))
                V3 = POINT(:,FACE(1,I)) - POINT(:,FACE(3,I))
                
                L = (SQRT(DOT_PRODUCT(V1,V1)) + SQRT(DOT_PRODUCT(V2,V2)) + SQRT(DOT_PRODUCT(V3,V3)))/3.
                IF(HASH_SIZE < L) THEN
                    HASH_SIZE = L
                END IF
            END DO
            
            HASH_SIZE = HASH_SIZE * 5.
        END IF
        
        HASH0%ELEMENT_TYP = ELEMENT_TYP
        
        HASH0%HASH_DOMAIN_MAX(:) = HASH_DOMAIN_MAX(:)
        HASH0%HASH_DOMAIN_MIN(:) = HASH_DOMAIN_MIN(:)
        
        HASH0%HASH_NUM1 = CEILING((HASH_DOMAIN_MAX(1)- HASH_DOMAIN_MIN(1))/HASH_SIZE)
        HASH0%HASH_NUM2 = CEILING((HASH_DOMAIN_MAX(2)- HASH_DOMAIN_MIN(2))/HASH_SIZE)
        HASH0%HASH_NUM3 = CEILING((HASH_DOMAIN_MAX(3)- HASH_DOMAIN_MIN(3))/HASH_SIZE)
        
        ALLOCATE(HASH0%ELEMENT(HASH0%HASH_NUM1, HASH0%HASH_NUM2, HASH0%HASH_NUM3))
        
        DO I=1,HASH0%HASH_NUM1
            DO J=1,HASH0%HASH_NUM2
                DO K=1,HASH0%HASH_NUM3
                    NULLIFY(HASH0%ELEMENT(I,J,K)%HEAD)
                    HASH0%ELEMENT%NUM = 0
                END DO
            END DO
        END DO
        
        IF(ELEMENT_TYP==1) THEN
            HASH_POINT_NUM = POINT_NUM
        ELSE IF(ELEMENT_TYP==2) THEN
            HASH_POINT_NUM = FACE_NUM
        END IF
        
        ALLOCATE(HASH_POINT(3,HASH_POINT_NUM))
        
        IF(ELEMENT_TYP==1) THEN
            HASH_POINT(:,:) = POINT(:,:)
        ELSE IF(ELEMENT_TYP==2) THEN
            DO I=1,FACE_NUM
                HASH_POINT(:,I) = (POINT(:,FACE(1,I)) + POINT(:,FACE(2,I)) + POINT(:,FACE(3,I)))/3.
            END DO
        END IF
        
        DO I=1,HASH_POINT_NUM
            CALL FIND_HASH_INDEX(HASH0, HASH_POINT(:,I), INDEX1, INDEX2, INDEX3)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2, INDEX3, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2, INDEX3, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2, INDEX3, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2-1, INDEX3, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2+1, INDEX3, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2, INDEX3+1, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2-1, INDEX3, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2-1, INDEX3, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2+1, INDEX3, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2+1, INDEX3, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2, INDEX3+1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2, INDEX3+1, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2-1, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2+1, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2-1, INDEX3+1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1, INDEX2+1, INDEX3+1, I)
            
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2-1, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2-1, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2+1, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2+1, INDEX3-1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2-1, INDEX3+1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2-1, INDEX3+1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1-1, INDEX2+1, INDEX3+1, I)
            CALL INSERT_ELEMENT(HASH0, INDEX1+1, INDEX2+1, INDEX3+1, I)
        END DO
        
    END SUBROUTINE
END MODULE HASHING_3D
