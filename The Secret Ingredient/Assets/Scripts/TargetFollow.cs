using UnityEngine;

public class FollowTarget : MonoBehaviour
{
    // Target to follow
    public Transform target;

    // Base speed for following
    public float baseSpeed = 5f;

    // Maximum allowed distance from the target before it speeds up
    public float maxDistance = 2f;

    // Multiplier to increase speed as the distance grows
    public float speedMultiplier = 2f;

    // Smooth damping effect settings
    public float smoothTime = 0.3f;
    private Vector3 velocity = Vector3.zero;

    // Rotation speed
    public float rotationSpeed = 5f;

    void Update()
    {
        // Ensure the target is assigned
        if (target != null)
        {
            // Calculate the distance to the target
            float distance = Vector3.Distance(transform.position, target.position);
            float adjustedSpeed = baseSpeed;

            // If distance is greater than maxDistance, increase the speed proportionally
            if (distance > maxDistance)
            {
                adjustedSpeed += (distance - maxDistance) * speedMultiplier;
            }

            // Smoothly move toward the target with spring damping effect and adjusted speed
            Vector3 targetPosition = Vector3.MoveTowards(transform.position, target.position, adjustedSpeed * Time.deltaTime);
            transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref velocity, smoothTime);

            // Smoothly rotate to match the target's rotation
            Quaternion targetRotation = target.rotation;
            transform.rotation = Quaternion.Lerp(transform.rotation, targetRotation, rotationSpeed * Time.deltaTime);
        }
    }
}
