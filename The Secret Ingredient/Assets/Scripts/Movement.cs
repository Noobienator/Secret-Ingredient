using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    [Header("Movement")]
    public float moveSpeed = 5f;
    public float groundDrag;

    [Header("Ground Check")]
    public LayerMask Ground;
    bool grounded;

    private Rigidbody rb;
    private Animator animator;

    public Transform cameraTransform; // Reference to the camera's transform
    public ParticleSystem moveParticleSystem; // Reference to the particle system

    Vector3 moveDirection;

    float horizontalInput;
    float verticalInput;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        animator = GetComponent<Animator>(); // Get the Animator component

        // Optional: Ensure the particle system is not emitting by default
        if (moveParticleSystem != null)
            moveParticleSystem.Stop();
    }

    private void Update()
    {
        grounded = Physics.Raycast(transform.position, Vector3.down, 5, Ground);
        MyInput();

        if (grounded)
            rb.drag = groundDrag;
        else
            rb.drag = 0;

        // Emit particles if moving, else stop
        EmitParticlesBasedOnMovement();

        // Update the "isMoving" animation parameter
        UpdateAnimationParameters();
    }

    private void FixedUpdate()
    {
        MovePlayer();
        RotateTowardsMovementDirection();
    }

    private void MyInput()
    {
        horizontalInput = Input.GetAxisRaw("Horizontal");
        verticalInput = Input.GetAxisRaw("Vertical");
    }

    private void MovePlayer()
    {
        // Movement relative to the camera's orientation in world space
        Vector3 forward = cameraTransform.forward;
        Vector3 right = cameraTransform.right;

        forward.y = 0f;
        right.y = 0f;

        forward.Normalize();
        right.Normalize();

        // Calculate the movement direction based on input
        moveDirection = (forward * verticalInput + right * horizontalInput).normalized;

        rb.AddForce(moveDirection * moveSpeed, ForceMode.Force);
    }

    private void RotateTowardsMovementDirection()
    {
        // Only rotate if there is movement input
        if (moveDirection != Vector3.zero)
        {
            // Calculate the target rotation based on moveDirection
            Quaternion targetRotation = Quaternion.LookRotation(moveDirection);

            Quaternion offsetRotation = Quaternion.Euler(0, -90, 0);
            targetRotation *= offsetRotation;

            // Smoothly interpolate to the target rotation
            transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, Time.deltaTime * 4f);
        }
    }

    private void EmitParticlesBasedOnMovement()
    {
        // Check if there is movement input
        bool isMoving = horizontalInput != 0 || verticalInput != 0;

        if (moveParticleSystem != null)
        {
            // Start emitting if moving, stop if not moving
            if (isMoving && !moveParticleSystem.isEmitting)
            {
                moveParticleSystem.Play();
            }
            else if (!isMoving && moveParticleSystem.isEmitting)
            {
                moveParticleSystem.Stop();
            }
        }
    }

    private void UpdateAnimationParameters()
    {
        // Check if there is movement input and set the "isMoving" parameter accordingly
        bool isMoving = horizontalInput != 0 || verticalInput != 0;

        // Update the animator's "isMoving" parameter
        if (animator != null)
        {
            animator.SetBool("isMoving", isMoving);
        }
    }
}
